output "bucket_state" {
  value       = aws_s3_bucket.state.bucket
  description = "Nama bucket remote state S3"
}
