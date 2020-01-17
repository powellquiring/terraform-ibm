# Two vpcs with one instance in each vpc
# instances with application loaded on two different vpcs with two different address ranges
# connect these two vpcs with transit gateway (not shown) to get master to remote to slave (can not got from slave to master)

provider "ibm" {
  region           = "us-south"
  ibmcloud_api_key = var.ibmcloud_api_key
  generation       = 2
}

locals {
  name_master  = lower(format("%s-l", var.prefix))
  name_slave = lower(format("%s-r", var.prefix))
}

data "ibm_resource_group" "app_rg" {
  name = var.resource_group_name
}
data "ibm_is_image" "default" {
  name = var.image_name
}
data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

module "vpc_master" {
  source = "../../terraform-ibm-vpc/"
  name   = local.name_master
  vpc_address_prefixes = [
    ["us-south-1", "10.0.0.0/16"],
    ["us-south-2", "10.1.0.0/16"],
    ["us-south-3", "10.2.0.0/16"],
  ]
  private_subnets = [
    ["us-south-1", "10.0.0.0/24"],
    ["us-south-2", "10.1.0.0/24"],
    ["us-south-3", "10.2.0.0/24"],
  ]
}

module "vpc_slave" {
  source = "../../terraform-ibm-vpc/"
  name   = local.name_slave
  vpc_address_prefixes = [
    ["us-south-1", "10.3.0.0/16"],
    ["us-south-2", "10.4.0.0/16"],
    ["us-south-3", "10.5.0.0/16"],
  ]
  private_subnets = [
    ["us-south-1", "10.3.0.0/24"],
    ["us-south-2", "10.4.0.0/24"],
    ["us-south-3", "10.5.0.0/24"],
  ]
}

module "sg_master" {
  source              = "../../terraform-ibm-security-groups/"
  name                = local.name_master
  description         = "Security group for example usage with EC2 instance"
  vpc_id              = module.vpc_master.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_tcp_rules   = ["ssh-tcp", "t3000"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_all_rule     = true
}

module "sg_slave" {
  source              = "../../terraform-ibm-security-groups/"
  name                = local.name_slave
  description         = "Security group for example usage with EC2 instance"
  vpc_id              = module.vpc_slave.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_tcp_rules   = ["ssh-tcp", "t3000"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_all_rule     = true
}

module "user_data_master" {
  source = "../app"
  remote = ibm_is_instance.instance_slave.primary_network_interface[0].primary_ipv4_address
}
module "user_data_slave" {
  source = "../app"
  // no remote access from slave
}

resource "ibm_is_instance" "instance_master" {
  name           = local.name_master
  vpc            = module.vpc_master.vpc_id
  image          = data.ibm_is_image.default.id
  profile        = var.profile
  resource_group = data.ibm_resource_group.app_rg.id
  zone           = module.vpc_master.private_zones[0]
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  primary_network_interface {
    subnet          = module.vpc_master.private_subnets[0]
    security_groups = [module.sg_master.this_security_group_id]
  }
  user_data = module.user_data_master.user_data
}
resource "ibm_is_instance" "instance_slave" {
  name           = local.name_master
  vpc            = module.vpc_slave.vpc_id
  image          = data.ibm_is_image.default.id
  profile        = var.profile
  resource_group = data.ibm_resource_group.app_rg.id
  zone           = module.vpc_slave.private_zones[0]
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  primary_network_interface {
    subnet          = module.vpc_slave.private_subnets[0]
    security_groups = [module.sg_slave.this_security_group_id]
  }
  user_data = module.user_data_slave.user_data
}

resource "ibm_is_floating_ip" "fip_master" {
  name   = local.name_master
  target = ibm_is_instance.instance_master.primary_network_interface[0].id
}
resource "ibm_is_floating_ip" "fip_slave" {
  name   = local.name_slave
  target = ibm_is_instance.instance_slave.primary_network_interface[0].id
}

output "master" {
  value = <<EOS
ssh root@${ibm_is_floating_ip.fip_master.address}
private ${ibm_is_instance.instance_master.primary_network_interface[0].primary_ipv4_address}
curl ${ibm_is_floating_ip.fip_master.address}:3000; # get hello world string
curl ${ibm_is_floating_ip.fip_master.address}:3000/info; # get the private IP address
curl ${ibm_is_floating_ip.fip_master.address}:3000/remote; # get the remote private IP address
EOS
}
output "slave" {
  value = <<EOS
ssh root@${ibm_is_floating_ip.fip_slave.address}
private ${ibm_is_instance.instance_slave.primary_network_interface[0].primary_ipv4_address}
curl ${ibm_is_floating_ip.fip_slave.address}:3000; # get hello world string
curl ${ibm_is_floating_ip.fip_slave.address}:3000/info; # get the private IP address
EOS
}