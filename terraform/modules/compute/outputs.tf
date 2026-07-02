#output "public_ip"{
#value=aws_instance.devsecops.public_ip
#}
output "alb_dns_name"{
value=aws_lb.devsecops_alb.dns_name
}
output "ec2_security_group_id" {
  description = "The ID of the Security Group attached to the DevSecOps Server"
  value       = aws_security_group.ec2_sg.id
}
