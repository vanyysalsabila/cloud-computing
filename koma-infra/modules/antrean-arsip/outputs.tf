output "topik_arn" {
  description = "ARN topik SNS pesanan"
  value       = aws_sns_topic.pesanan.arn
}

output "antrean_url" {
  description = "URL antrean SQS utama"
  value       = aws_sqs_queue.antrean.url
}

output "dlq_url" {
  description = "URL dead-letter queue atau null jika tanpa DLQ"
  value       = var.dengan_dlq ? aws_sqs_queue.gagal[0].url : null
}

output "bucket" {
  description = "Nama bucket S3 arsip"
  value       = aws_s3_bucket.arsip.bucket
}

output "fungsi" {
  description = "Nama fungsi Lambda pengarsip"
  value       = aws_lambda_function.pengarsip.function_name
}

output "memori_mb" {
  description = "Alokasi memori Lambda dalam MB"
  value       = aws_lambda_function.pengarsip.memory_size
}
