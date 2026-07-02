variable "vpc_cidr"{
type=string
description="The CIDR block for the VPC"
}

#variable "public_subnet_cidr"{
##type=string
#description = "The CIDR block for the public subnet"
#}

variable "environment"{
type= string
description ="Deployment environment (e.g., dev, prod)"
}

variable "public_subnet_1_cidr"{
type=string
description = "The CIDR block-1 for the public subnet"
}

variable "public_subnet_2_cidr"{
type=string
description = "The CIDR block-2 for the public subnet"
}

variable "private_subnet_cidr"{
type=string
description = "The CIDR block for the private subnet"
}
