resource "aws_vpc" "this"{
cidr_block = var.vpc_cidr
enable_dns_hostnames = true
enable_dns_support = true
tags = { Name = "instamart-${var.environment}-vpc"}
}

resource "aws_internet_gateway" "igw"{
vpc_id=aws_vpc.this.id
tags= { Name="instamart-${var.environment}-igw" }
}

# --- PUBLIC SUBNETS (For the Load Balancer & NAT) ---
resource "aws_subnet" "public_1"{
vpc_id=aws_vpc.this.id
cidr_block=var.public_subnet_1_cidr
map_public_ip_on_launch=true
availability_zone="us-east-1a"
tags={Name="instamart-${var.environment}-public-1"}
}

resource "aws_subnet" "public_2"{
vpc_id=aws_vpc.this.id
cidr_block=var.public_subnet_2_cidr
map_public_ip_on_launch=true
availability_zone="us-east-1b"
tags={Name="instamart-${var.environment}-public-2"}
}

# --- PRIVATE SUBNET (For your EC2 Server) ---
resource "aws_subnet" "private"{
vpc_id=aws_vpc.this.id
cidr_block=var.private_subnet_cidr
map_public_ip_on_launch=false     ## No public IPs allowed here!
availability_zone="us-east-1a"
tags={Name="instamart-${var.environment}-private"}
}


#--NAT GATEWAY
resource "aws_eip" "nat_eip"{
domain="vpc"
}

resource "aws_nat_gateway" "nat"{
allocation_id = aws_eip.nat_eip.id
subnet_id = aws_subnet.public_1.id
depends_on = [aws_internet_gateway.igw]
tags = { Name = "instamart-${var.environment}-nat"}
}

##ROUTE TABLES
resource "aws_route_table" "public_rt"{
vpc_id=aws_vpc.this.id
route{
cidr_block="0.0.0.0/0"
gateway_id=aws_internet_gateway.igw.id
}
}

resource "aws_route_table" "private_rt"{
vpc_id=aws_vpc.this.id
route{
cidr_block = "0.0.0.0/0"
nat_gateway_id = aws_nat_gateway.nat.id
}
}

##ROUTE TABLE ASSOCIATIONS
resource "aws_route_table_association" "pub_1"{
subnet_id = aws_subnet.public_1.id
route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_2"{
subnet_id = aws_subnet.public_2.id
route_table_id=aws_route_table.public_rt.id
}

resource "aws_route_table_association" "priv_1"{
subnet_id= aws_subnet.private.id
route_table_id = aws_route_table.private_rt.id
}
