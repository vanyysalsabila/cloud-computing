output "api_url" {
  value       = "http://${aws_instance.api.public_ip}"
  description = "URL HTTP server koma-api"
}

output "parameter_rahasia" {
  value       = aws_ssm_parameter.db_password.name
  description = "Nama parameter SSM tempat password database disimpan"
}

output "kunci_kms" {
  value       = aws_kms_alias.m05.name
  description = "Alias kunci KMS Modul 05"
}

output "bucket_laporan" {
  value       = aws_s3_bucket.laporan.bucket
  description = "Nama bucket laporan privat Modul 05"
}
