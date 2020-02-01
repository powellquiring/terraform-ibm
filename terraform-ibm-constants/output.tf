# default zone cidr ranges for the vpc.  Terraform does not currently allow setting or changing these: 
# https://github.ibm.com/blueprint/bluemix-terraform-provider-dev/issues/628

# default vpc prefix values - currently (2019/02/26) not possible in terraform to specify different prefixes:
# Default CIDR prefixes for vpcs
# eu-de    = ["10.243.0.0/18 z1", "10.243.64.0/18 z2", "10.243.128.0/18 z3"]
# us-south = ["10.240.0.0/18 z1", "10.240.64.0/18 z2", "10.240.128.0/18 z3"]

output "azs" {
  value = {
    us-south = ["us-south-1", "us-south-2", "us-south-3"]
    us-east  = ["us-east-1", "us-east-2", "us-east-3"]
    eu-de    = ["eu-de-1", "eu-de-2", "eu-de-3"]
  }
}

output "public_subnets" {
  value = {
    us-south = [
      ["us-south-1", "10.240.0.0/24"],
      ["us-south-2", "10.240.64.0/24"],
      ["us-south-3", "10.240.128.0/24"],
    ]
  }
  #eu-de             = ["10.243.0.0/24", "10.243.64.0/24", "10.243.128.0/24"]
}

output "private_subnets" {
  value = {
    us-south = ["10.240.1.0/24", "10.240.65.0/24", "10.240.129.0/24"]
    eu-de    = ["10.243.1.0/24", "10.243.65.0/24", "10.243.129.0/24"]
  }
}


