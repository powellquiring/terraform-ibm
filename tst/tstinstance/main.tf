provider "ibm" {
  region           = "us-south"
  ibmcloud_api_key = var.ibmcloud_api_key
  generation       = 2
}

locals {
  name     = format("%s-tstinstance", var.prefix)
  nameleft = lower(format("%s-tstinstance-left", var.prefix))
  left     = 0
  right    = 1
}

data "ibm_resource_group" "app_rg" {
  name = var.resource_group_name
}
data "ibm_is_image" "default" {
  name = var.image_name
}

module "vpc" {
  source = "../../terraform-ibm-vpc/"
  name   = local.name
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

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

module "security_group" {
  source              = "../../terraform-ibm-security-groups/"
  name                = local.name
  description         = "Security group for example usage with EC2 instance"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_tcp_rules   = ["ssh-tcp", "http-80-tcp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_all_rule     = true
}

# LEFT: instance left on a private subnet, give it a fip
resource "ibm_is_instance" "instanceleft" {
  name           = local.nameleft
  vpc            = module.vpc.vpc_id
  image          = data.ibm_is_image.default.id
  profile        = var.profile
  resource_group = data.ibm_resource_group.app_rg.id
  zone           = module.vpc.private_zones[local.left]
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  primary_network_interface {
    subnet          = module.vpc.private_subnets[local.left]
    security_groups = [module.security_group.this_security_group_id]
  }
}

resource "ibm_is_floating_ip" "fipleft" {
  name   = local.nameleft
  target = ibm_is_instance.instanceleft.primary_network_interface[0].id
}

output "sshleft" {
  value = "ssh root@${ibm_is_floating_ip.fipleft.address}"
}