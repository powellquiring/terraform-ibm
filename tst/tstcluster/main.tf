variable ibmcloud_api_key { }
variable "prefix" {
    default = "pfqk00"
}
locals {
  region = "us-south"
  name = "${var.prefix}"
}

provider "ibm" {
  region          = local.region
  ibmcloud_api_key = var.ibmcloud_api_key
  generation      = 1
}

module "ibm_constants" {
  source = "../../terraform-ibm-constants/"
}

module "vpc" {
  source = "../../terraform-ibm-vpc/"
  name   = local.name
  vpc_address_prefixes  = [
    [module.ibm_constants.azs[local.region][0], "10.0.0.0/16"],
    [module.ibm_constants.azs[local.region][1], "10.1.0.0/16"],
    [module.ibm_constants.azs[local.region][2], "10.2.0.0/16"],
  ]
  public_subnets  = [
    [module.ibm_constants.azs[local.region][0], "10.0.0.0/16"],
    [module.ibm_constants.azs[local.region][1], "10.1.0.0/16"],
    [module.ibm_constants.azs[local.region][2], "10.2.0.0/16"],
  ]
}

resource "ibm_container_vpc_cluster" "cluster" {
  name              = local.name
  vpc_id              = module.vpc.vpc_id
  flavor            = "c2.2x4"
  worker_count      = "1"
  #resource_group_id = data.ibm_resource_group.resource_group.id
  zones {
    subnet_id = module.vpc.public_subnets[0]
    name      = module.ibm_constants.azs[local.region][0]
  }
}
