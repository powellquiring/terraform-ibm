variable ibmcloud_api_key {}
variable "prefix" {
  default = "f00"
}
locals {
  region = "us-east"
  name   = "${var.prefix}"
}

provider "ibm" {
  region           = local.region
  ibmcloud_api_key = var.ibmcloud_api_key
  generation       = 2
}
module "ibm_constants" {
  source = "../../terraform-ibm-constants/"
}

module "vpc" {
  source = "../../terraform-ibm-vpc/"
  name   = local.name
  # create_vpc = false
  vpc_address_prefixes = [
    [module.ibm_constants.azs[local.region][0], "10.0.0.0/16"],
    [module.ibm_constants.azs[local.region][1], "10.1.0.0/16"],
    [module.ibm_constants.azs[local.region][2], "10.2.0.0/16"],
  ]
  private_subnets = [
    [module.ibm_constants.azs[local.region][0], "10.0.0.0/16"],
    [module.ibm_constants.azs[local.region][1], "10.1.0.0/16"],
    [module.ibm_constants.azs[local.region][2], "10.2.0.0/16"],
  ]
}

output vpc_id {
  value = module.vpc.vpc_id
}

module "vpccount" {
  source = "../../terraform-ibm-vpc/"
  name   = "${local.name}count"
  private_subnets_address_count = [
    [module.ibm_constants.azs[local.region][0], 256],
    [module.ibm_constants.azs[local.region][1], 512],
    [module.ibm_constants.azs[local.region][2], 256],
  ]
}

output vpc_idcount {
  value = module.vpccount.vpc_id
}
