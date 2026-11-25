# Pagar tingkat akun (Modul 05, dijalankan SEKALI dan TIDAK di-destroy selama kursus).
# S3 Block Public Access tingkat akun mengalahkan pengaturan per bucket: bucket mana pun di
# akun ini tidak dapat dibuka ke publik, termasuk oleh stack m05-rawan bila tidak sengaja
# di-apply. Resource ini tidak berbiaya.
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

provider "aws" {
  region = var.region
}

resource "aws_s3_account_public_access_block" "akun" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
