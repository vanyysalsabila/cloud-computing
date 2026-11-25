data "aws_caller_identity" "saya" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_vpc" "bawaan" {
  default = true
}

locals {
  awalan = "koma-${var.nim}-m05"
  bucket = "${local.awalan}-laporan-${data.aws_caller_identity.saya.account_id}"
}

# ----------------------------------------------------------------- identitas server

resource "aws_iam_role" "api" {
  name = "${local.awalan}-api"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# "Supaya tidak repot soal izin."
resource "aws_iam_role_policy" "api" {
  name = "akses-penuh"
  role = aws_iam_role.api.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "api" {
  name = "${local.awalan}-api"
  role = aws_iam_role.api.name
}

# ----------------------------------------------------------------- jaringan

resource "aws_security_group" "api" {
  name        = "${local.awalan}-api"
  description = "koma-api"
  vpc_id      = data.aws_vpc.bawaan.id
  tags        = { Name = "${local.awalan}-api", peran = "api" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.api.id
  description       = "SSH untuk perawatan"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.api.id
  description       = "HTTP"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "semua" {
  security_group_id = aws_security_group.api.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ----------------------------------------------------------------- server

resource "aws_instance" "api" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.api.id]
  iam_instance_profile        = aws_iam_instance_profile.api.name
  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    versi       = var.versi
    db_password = var.db_password
    aplikasi_gz = base64gzip(file("${path.module}/../../app/koma_api.py"))
  })

  tags = { Name = "${local.awalan}-api", peran = "api", versi = var.versi }
}

# ----------------------------------------------------------------- object storage

resource "aws_s3_bucket" "laporan" {
  bucket        = local.bucket
  force_destroy = true
  tags          = { Name = "${local.awalan}-laporan", peran = "laporan" }
}

# "Pelanggan mengunduh laporannya langsung dari tautan bucket."
resource "aws_s3_bucket_public_access_block" "laporan" {
  bucket                  = aws_s3_bucket.laporan.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "laporan" {
  bucket     = aws_s3_bucket.laporan.id
  depends_on = [aws_s3_bucket_public_access_block.laporan]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "UnduhLaporan"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::${local.bucket}/*"
    }]
  })
}

resource "aws_s3_object" "laporan" {
  bucket       = aws_s3_bucket.laporan.id
  key          = "laporan/pelanggan-contoh.csv"
  content      = "id,nama,kelas_data\n1,Pelanggan Contoh,rahasia\n"
  content_type = "text/csv"
}
