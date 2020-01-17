variable ibmcloud_api_key { }
variable "prefix" {
    default = "pfqtf03"
}
locals {
  region = "us-south"
  lname = "${var.prefix}-l"
  rname = "${var.prefix}-r"
}

provider "ibm" {
  region          = local.region
  ibmcloud_api_key = var.ibmcloud_api_key
  generation      = 2
}

module "vpcl" {
  source = "../../terraform-ibm-vpc/"
  name   = local.lname
  vpc_address_prefixes  = [
    ["us-south-1", "10.0.0.0/16"],
    ["us-south-2", "10.1.0.0/16"],
    ["us-south-3", "10.2.0.0/16"],
  ]
  private_subnets  = [
    ["us-south-1", "10.0.0.0/24"],
    ["us-south-2", "10.1.0.0/24"],
    ["us-south-3", "10.2.0.0/24"],
  ]
}

module "vpcr" {
  source = "../../terraform-ibm-vpc/"
  name   = local.rname
  vpc_address_prefixes  = [
    ["us-south-1", "10.3.0.0/16"],
    ["us-south-2", "10.4.0.0/16"],
    ["us-south-3", "10.5.0.0/16"],
  ]
  private_subnets  = [
    ["us-south-1", "10.3.0.0/24"],
    ["us-south-2", "10.4.0.0/24"],
    ["us-south-3", "10.5.0.0/24"],
  ]
}