provider "aws" {
  region = "us-east-1"
}

# 1. Tell Terraform to find your specific Instamart VPC
data "aws_vpc" "instamart" {
  filter {
    name   = "tag:Name"
    values = ["*instamart*"] # Adjust this if your VPC has a different name tag
  }
}

# 2. Tell Terraform to find the private subnets inside that VPC
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.instamart.id]
  }
  
  # This filter ensures we only grab private subnets (no auto-assigned public IPs)
  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"] 
  }
}
