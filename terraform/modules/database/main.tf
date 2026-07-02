resource "aws_security_group" "rds_sg"{
name = "instamart-${var.environment}-rds-sg"
description = "Allow inbound PostgreSQL traffic from EC2"
vpc_id=var.vpc_id

ingress{
description = "PostgreSQL strictly from Compute SG"
from_port=5432
to_port=5432
protocol="tcp"
security_groups=[var.allowed_security_group_id]
}

egress{
from_port=0
to_port=0
protocol="-1"
cidr_blocks=["0.0.0.0/0"]
}

tags={
Name="instamart-${var.environment}-rds-sg"
Environment=var.environment
}
}

resource "aws_db_subnet_group" "private_db_subnet" {
  name       = "instamart-${lower(var.environment)}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name        = "Instamart ${var.environment} DB Subnet Group"
    Environment = var.environment
  }
}

resource "random_password" "db_password"{
length=16
special=true
override_special="!#$%&*()-_=+[]{}<>:?"
}

#resource "aws_secretsmanager_secret" "db_credentials"{
#name = "instamart/${var.environment}/database-credentials"
#description = "Database credentials for the Instamart ${var.environment} environment"
#recovery_window_in_days=0
#}

#resource "aws_secretsmanager_secret_version" "db_credentials_version"{
#secret_id = aws_secretsmanager_secret.db_credentials.id
#secret_string=jsonencode({
#username = var.db_username
#password=random_password.db_password.result
#engine="postgres"
#host=aws_db_instance.postgres_db.endpoint
#port=aws_db_instance.postgres_db.port
#dbname=var.db_name
#})
#}



resource "aws_db_instance" "postgres_db"{
  identifier             = "instamart-${lower(var.environment)}-db"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  
  db_name              = var.db_name
  username             = var.db_username
  
  # Linked the database password to our newly generated random password
  password             = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.private_db_subnet.name 
  publicly_accessible    = false 
  skip_final_snapshot    = true  
  
  tags = {
    Environment = var.environment
    Project     = "Instamart"
  }
}

resource "aws_ssm_parameter" "db_credentials" {
  name        = "/instamart/${lower(var.environment)}/database/credentials"
  description = "Secure connection details for the ${var.environment} database"
  type        = "SecureString"
  
  value = jsonencode({
    endpoint   = aws_db_instance.postgres_db.endpoint
    username   = var.db_username
    password   = random_password.db_password.result
    dbname     = var.db_name
    spring_url = "jdbc:postgresql://${aws_db_instance.postgres_db.endpoint}/${var.db_name}"
  })
}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "instamart-frontend-${random_string.suffix.result}" # S3 bucket names must be globally unique
  
  tags = {
    Name        = "Instamart Frontend"
    Environment = "Dev"
  }
}

# Generate a random string to ensure the bucket name is unique
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
