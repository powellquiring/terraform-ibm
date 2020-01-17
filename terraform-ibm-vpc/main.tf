terraform {
  required_version = ">= 0.10.3" # introduction of Local Values configuration language feature
}

locals {
  vpc_address_prefix_count           = var.create_vpc ? length(var.vpc_address_prefixes) : 0
  public_subnet_count                = var.create_vpc ? length(var.public_subnets) : 0
  private_subnet_count               = var.create_vpc ? length(var.private_subnets) : 0
  private_subnet_address_count_count = var.create_vpc ? length(var.private_subnets_address_count) : 0
  public_subnet_address_count_count  = var.create_vpc ? length(var.public_subnets_address_count) : 0
  vpc_id                             = ibm_is_vpc.this[0].id
}

######
# VPC
######
resource "ibm_is_vpc" "this" {
  name           = var.name
  count          = var.create_vpc ? 1 : 0
  resource_group = var.resource_group
  address_prefix_management = local.vpc_address_prefix_count == 0 ? "auto" : "manual"
  default_network_acl = var.default_network_acl
  tags                = concat(var.tags, var.vpc_tags)
}

resource "ibm_is_vpc_address_prefix" "vpc_address_prefixes_create" {
  count = local.vpc_address_prefix_count
  name  = format("%s-%d", var.name, count.index)
  zone  = var.vpc_address_prefixes[count.index][0]
  vpc   = local.vpc_id
  cidr  = var.vpc_address_prefixes[count.index][1]
  /* TODO
  provisioner "local-exec" {
    command = "sleep ${count.index}0;"
  }
  TODO */
}

/*
resource "null_resource" "vpc_address_prefixes_create" {
  count = "${local.vpc_address_prefix_count}"
  provisioner "local-exec" {
    command = "sleep ${count.index}0; ibmcloud is vpc-address-prefix-create ${format("%s_%d", var.name, count.index)} ${local.vpc_id} ${element(var.vpc_address_prefixes, count.index*2)} ${element(var.vpc_address_prefixes, count.index*2+1)}"
  }
}
*/

# attach a network acl to the right subnet

################
# Private subnets 
################
resource "ibm_is_subnet" "private" {
  count           = local.private_subnet_count
  depends_on      = [ibm_is_vpc_address_prefix.vpc_address_prefixes_create]
  name            = format("%s-private-subnet%d", var.name, count.index)
  vpc             = local.vpc_id
  ipv4_cidr_block = var.private_subnets[count.index][1]
  zone            = var.private_subnets[count.index][0]
}

resource "ibm_is_subnet" "private_address_count" {
  count                    = local.private_subnet_address_count_count
  name                     = format("%s-private-subnet_count%d", var.name, count.index)
  vpc                      = local.vpc_id
  total_ipv4_address_count = var.private_subnets_address_count[count.index][1]
  zone                     = var.private_subnets_address_count[count.index][0]
}

################
# Public subnets with internet gateway's attached
################
resource "ibm_is_subnet" "public" {
  count           = local.public_subnet_count
  name            = format("%s-public-subnet%d", var.name, count.index)
  vpc             = local.vpc_id
  ipv4_cidr_block = var.public_subnets[count.index][1]
  zone            = var.public_subnets[count.index][0]
  public_gateway  = ibm_is_public_gateway.this[count.index].id
  network_acl     = ""
}

resource "ibm_is_subnet" "public_address_count" {
  count                    = local.public_subnet_address_count_count
  name                     = format("%s-public-subnet_count%d", var.name, count.index)
  vpc                      = local.vpc_id
  total_ipv4_address_count = var.public_subnets_address_count[count.index][1]
  zone                     = var.public_subnets_address_count[count.index][0]
}

###################
# Internet Gateway
#
# one public gateway connected to public subnet 0.  Or one public gateway per subnet
###################
resource "ibm_is_public_gateway" "this" {
  count = local.public_subnet_count
  name  = format("%s-gateway-%d", var.name, count.index)
  vpc   = local.vpc_id
  zone  = var.public_subnets[count.index][0]
}

/*--------------------------
# work around bug: https://github.ibm.com/blueprint/bluemix-terraform-provider-dev/issues/631
resource "null_resource" "subnet_public_gateway_detach" {
  count = local.public_subnet_count
  provisioner "local-exec" {
    when    = destroy
    command = "ibmcloud is subnet-public-gateway-detach ${element(ibm_is_subnet.public.*.id, count.index)} -f; sleep 5"
  }
}
----------------------------*/
