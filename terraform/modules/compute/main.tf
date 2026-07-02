resource "aws_iam_role" "ssm_role"{
name="instamart-${var.environment}-ssm-role"
assume_role_policy=jsonencode({
Version="2012-10-17"
Statement=[
{
Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
# Attach the AWS-managed policy that grants SSM permissions
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



# Create an Instance Profile to attach the role to the EC2 instance
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "instamart-${var.environment}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

#Security Groups
#ALB Security Group: Accepts public internet traffic on Port 80
resource "aws_security_group" "alb_sg"{
name = "instamart-${var.environment}-alb-sg"
vpc_id = var.vpc_id
ingress {
 from_port=80
 to_port=80
 protocol = "tcp"
 cidr_blocks=["0.0.0.0/0"]
}
ingress {
  description = "Allow SonarQube traffic from internet"
  from_port   = 9000
  to_port     = 9000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {
    description = "Allow Backend API traffic"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"] 
}
}


resource "aws_security_group" "ec2_sg"{
name = "instamart-${var.environment}-ec2-private-sg"
vpc_id = var.vpc_id
ingress {
 from_port=8080 #Jenkins
 to_port=8080 
 protocol = "tcp"
 security_groups = [aws_security_group.alb_sg.id]
}
ingress {
 from_port=9000 #SonarQube
 to_port=9000
 protocol = "tcp"
 security_groups = [aws_security_group.alb_sg.id]
}
ingress {
    description = "Allow ALB to access Spring Boot"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    # Best practice is to restrict this to your ALB's security group ID, 
    # but 0.0.0.0/0 works for immediate testing if your EC2 is in a private subnet.
    cidr_blocks = ["0.0.0.0/0"] 
  }
egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
}
}


data "aws_ami" "ubuntu"{
most_recent=true
owners=["099720109477"]
filter{
 name="name"
 values=["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
}
}
#resource "aws_security_group" "devsecops" {
#name = "instamart-${var.environment}-devsecops-sg"
#description="security group for devsecops tools"
#vpc_id=var.vpc_id

#dynamic "ingress"{
#for_each=[80,8080,9000,8081]
#content{
#from_port=ingress.value
#to_port=ingress.value
#protocol="tcp"
#cidr_blocks=["0.0.0.0/0"]
#}
#}
#egress{
#from_port=0
#to_port=0
#protocol="-1"
#cidr_blocks=["0.0.0.0/0"]
#}
#}
resource "aws_key_pair" "ansible_auth" {
  key_name   = "instamart-ansible-key"
  public_key = file("~/.ssh/instamart_key.pub")
}
resource "aws_instance" "devsecops" {
ami=data.aws_ami.ubuntu.id
instance_type=var.instance_type
subnet_id=var.private_subnet_id
vpc_security_group_ids=[aws_security_group.ec2_sg.id]
#key_name="instamart-key"#using ssm login
key_name      = aws_key_pair.ansible_auth.key_name
iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
root_block_device{
volume_size=30
volume_type="gp3"
}
tags={Name="Instamart-${var.environment}-DevSecOps-Server"}
}

resource "aws_lb" "devsecops_alb"{
name="instamart-${var.environment}-alb"
internal = false
load_balancer_type = "application"
security_groups = [aws_security_group.alb_sg.id]
subnets = [var.public_subnet_1_id,var.public_subnet_2_id]
}

resource "aws_lb_target_group" "jenkins_tg" {
  name     = "jenkins-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/login"
    port = "8080"
  }
}

resource "aws_lb_target_group_attachment" "jenkins"{
target_group_arn = aws_lb_target_group.jenkins_tg.arn
target_id=aws_instance.devsecops.id
port=8080
}

resource "aws_lb_listener" "jenkins_front_end"{
load_balancer_arn = aws_lb.devsecops_alb.arn
port ="80"
protocol ="HTTP"
default_action {
type="forward"
target_group_arn = aws_lb_target_group.jenkins_tg.arn
}
}
# Create the Target Group for SonarQube
resource "aws_lb_target_group" "sonarqube_tg" {
  name     = "instamart-dev-sonar-tg"
  port     = 9000
  protocol = "HTTP"
  vpc_id   = var.vpc_id # Ensure this matches how you pass VPC ID in this module

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200,302"
  }
}

# Attach your DevSecOps server to the Target Group
resource "aws_lb_target_group_attachment" "sonarqube_attach" {
  target_group_arn = aws_lb_target_group.sonarqube_tg.arn
  target_id        = aws_instance.devsecops.id
  port             = 9000
}
resource "aws_lb_listener" "sonarqube_listener" {
  load_balancer_arn = aws_lb.devsecops_alb.arn # Ensure this matches your ALB resource name
  port              = "9000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube_tg.arn
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "ec2_app_role" {
  name = "instamart-${lower(var.environment)}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_db_read_policy" {
  name        = "instamart-${lower(var.environment)}-ssm-read-policy"
  description = "Allows EC2 to read DB credentials from SSM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory"
        ]
        # Securely lock this down to the exact parameter path we created in the DB module
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/instamart/${lower(var.environment)}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_db_read_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = aws_iam_policy.ssm_db_read_policy.arn
}

# 5. Create the Instance Profile (This is what actually attaches to the EC2 server)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "instamart-${lower(var.environment)}-ec2-profile"
  role = aws_iam_role.ec2_app_role.name
}
#Create a Target Group for the Spring Boot Backend
resource "aws_lb_target_group" "backend_tg" {
  name     = "instamart-backend-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id = var.vpc_id
  #vpc_id   = aws_vpc.main.id # Ensure this matches your VPC resource name

  health_check {
    path                = "/actuator/health" # Or whichever health endpoint Spring Boot uses
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }
}
#  Attach your EC2 instance to the Backend Target Group
resource "aws_lb_target_group_attachment" "backend_attach" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.devsecops.id # Ensure this matches your EC2 resource name
  port             = 8081
}

#  Create a Listener on the ALB for standard HTTP traffic
resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.devsecops_alb.arn # Ensure this matches your ALB resource name
  port              = "8081"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}
