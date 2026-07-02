module "dev_network"{
source="../../modules/vpc"
vpc_cidr="10.0.0.0/16"
public_subnet_1_cidr="10.0.1.0/24"
public_subnet_2_cidr="10.0.2.0/24"
private_subnet_cidr="10.0.3.0/24"
environment="Dev"
}

module "dev_compute"{
source="../../modules/compute"
vpc_id=module.dev_network.vpc_id
public_subnet_1_id=module.dev_network.public_subnet_1_id
public_subnet_2_id=module.dev_network.public_subnet_2_id
private_subnet_id=module.dev_network.private_subnet_id
instance_type="t3.large"
environment="Dev"
}

module "dev_database" {
  source                    = "../../modules/database"
  environment               = "Dev"
  vpc_id                    = module.dev_network.vpc_id
  
  # THIS IS THE SECURE LINK: We grab the SG ID from the dev_compute module!
  allowed_security_group_id = module.dev_compute.ec2_security_group_id
  
  # ADD THIS: Pass the subnets to force the DB placement
  # (AWS requires 2 subnets for a group. We mix private/public here just to satisfy the 2 AZ requirement for Dev)
  db_subnet_ids             = [module.dev_network.private_subnet_id, module.dev_network.public_subnet_2_id]
  
  db_name                   = "instamartdev"
  db_username               = "postgres"
  # Notice: No password passed here. The module handles it via AWS Secrets Manager!
}
