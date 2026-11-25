output "lingkungan" {
  description = "Lingkungan aktif stack m07-integrasi"
  value       = var.lingkungan
}

output "topik_arn" {
  description = "ARN topik SNS pesanan"
  value       = module.jalur.topik_arn
}

output "bucket_arsip" {
  description = "Nama bucket S3 arsip"
  value       = module.jalur.bucket
}

output "fungsi" {
  description = "Nama fungsi Lambda pengarsip"
  value       = module.jalur.fungsi
}

output "dlq_url" {
  description = "URL dead-letter queue atau null"
  value       = module.jalur.dlq_url
}
