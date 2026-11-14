output "vpc_id" {
  value       = aws_vpc.utama.id
  description = "ID VPC m03"
}

output "cidr_vpc" {
  value       = aws_vpc.utama.cidr_block
  description = "CIDR block VPC m03"
}

output "public_subnet_ids" {
  value       = aws_subnet.publik[*].id
  description = "ID subnet publik m03"
}

output "private_subnet_ids" {
  value       = aws_subnet.privat[*].id
  description = "ID subnet privat m03"
}
