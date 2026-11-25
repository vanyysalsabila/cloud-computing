output "alb_url" {
  value       = "http://${aws_lb.api.dns_name}"
  description = "Alamat HTTP Application Load Balancer Modul 06"
}

output "aktif" {
  value       = var.aktif
  description = "Target group aktif yang menerima lalu lintas ALB"
}

output "id_hijau" {
  value       = aws_instance.hijau.id
  description = "ID instance server hijau"
}

output "log_group" {
  value       = aws_cloudwatch_log_group.api.name
  description = "Nama CloudWatch Log Group server hijau"
}

output "dasbor" {
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.api.dashboard_name}"
  description = "Tautan konsol CloudWatch Dashboard Modul 06"
}
