#output "devsecops_server_public_ip"{
#value =module.dev_compute.public_ip
#}
output "jenkins_url" {
value = "http://${module.dev_compute.alb_dns_name}"
}
output "database_endpoint" {
  description = "The dynamic connection endpoint for the Dev RDS instance"
  value       = module.dev_database.rds_endpoint
}
