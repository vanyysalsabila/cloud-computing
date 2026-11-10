output "pembangun" {
  description = "Informasi instance pembangun"
  value = {
    id        = aws_instance.pembangun.id
    ip_publik = aws_instance.pembangun.public_ip
  }
}

output "ami" {
  description = "AMI hasil panggangan"
  value = {
    id   = try(aws_ami_from_instance.api[0].id, null)
    nama = try(aws_ami_from_instance.api[0].name, null)
  }
}

output "api" {
  description = "Informasi instance API production"
  value = {
    id         = try(aws_instance.api[0].id, null)
    ip_publik  = try(aws_instance.api[0].public_ip, null)
    versi      = var.versi
    url_health = try("http://${aws_instance.api[0].public_ip}/health", null)
    url_versi  = try("http://${aws_instance.api[0].public_ip}/versi", null)
  }
}
