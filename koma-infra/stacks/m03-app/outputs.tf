output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "DNS name publik ALB"
}

output "alb_arn" {
  value       = aws_lb.alb.arn
  description = "ARN ALB"
}

output "web_private_ip" {
  value       = aws_instance.web.private_ip
  description = "IP privat instance web"
}

output "db_private_ip" {
  value       = aws_instance.db.private_ip
  description = "IP privat instance db"
}
