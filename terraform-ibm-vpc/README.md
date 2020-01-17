copied from https://github.com/terraform-aws-modules/terraform-aws-vpc

# Usage
```
module "myvpc" {
  source = "../terraform-ibm-vpc/"
  name = myvpc
  azs             = ["us-south-1", "us-south-2", "us-south-3"]
  public_subnets  = ["10.240.0.0/24", "10.240.64.0/24", "10.240.128.0/24"]
  private_subnets  = ["10.240.1.0/24", "10.240.65.0/24", "10.240.129.0/24"]
}
```

This will result in creating the following 10 resources:
- vpc
- three private subnets distributed over the associate availability zones.
- three public subnets distributed over the associate availability zones.
- three public gateways connected to the public subnets

Use these to initialize the default security group
```
security_group     = "${module.vpc.default_security_group}"
security_group_computed     = true
```
