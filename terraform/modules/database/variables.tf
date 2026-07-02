variable "environment"{
description = "The environment (dev,uat,preprod,prod,etc).."
type =string
}

variable "vpc_id"{
description = "The ID of the VPC where the RDS will be deployed"
type = string
}

variable "allowed_security_group_id"{
description = "The Security Group ID of the EC2 instance allowed to connect to RDS"
type = string
}

variable "db_subnet_ids" {
  description = "A list of private subnet IDs where the RDS instance will be deployed"
  type        = list(string)
}

variable "db_name"{
description = "Name of the default database"
type = string
default = "instamart"
}

variable "db_username"{
description = "Master username for PostgreSQL"
type = string
default = "postgres"
}
