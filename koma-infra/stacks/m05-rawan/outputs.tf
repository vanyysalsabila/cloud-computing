output "api_url" {
  value = "http://${aws_instance.api.public_ip}"
}

output "db_password" {
  value = var.db_password
}
