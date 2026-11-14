output "bucket_arsip" {
  value       = aws_s3_bucket.arsip.bucket
  description = "Nama bucket arsip m04"
}

output "instance_db_id" {
  value       = aws_instance.db.id
  description = "ID instance server DB"
}

output "volume_data_id" {
  value       = aws_ebs_volume.data.id
  description = "ID volume EBS data"
}
