# Modul 05 — stack aman. Ikuti naskah Bagian C: setiap TODO menutup satu temuan stack rawan.
# Enkripsi state (enkripsi.tf) ditulis di Bagian D sebelum `tofu init` pertama.

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
  awalan    = "koma-${var.nim}-m05"
  akun      = data.aws_caller_identity.saya.account_id
  parameter = "/koma/${var.nim}/m05/db-password"
  # ARN disusun dari nilai yang sudah diketahui saat plan, agar kebijakan IAM dan bucket
  # tampil utuh di plan JSON dan dapat diperiksa Conftest sebelum apply.
  arn_parameter = "arn:aws:ssm:${var.region}:${local.akun}:parameter${local.parameter}"
  bucket        = "${local.awalan}-laporan-${local.akun}"
}

# ---------------------------------------------------------------------------
# C.1 — Kunci KMS Khusus Modul 05 (Rotasi Aktif)
# ---------------------------------------------------------------------------

resource "aws_kms_key" "m05" {
  description             = "Kunci KMS Modul 05 (${local.awalan})"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Name  = "${local.awalan}-kunci"
    peran = "kunci"
  }
}

resource "aws_kms_alias" "m05" {
  name          = "alias/${local.awalan}"
  target_key_id = aws_kms_key.m05.key_id
}

# ---------------------------------------------------------------------------
# C.2 — Rahasia Dibangkitkan Acak & Disimpan di SSM Parameter Store
# ---------------------------------------------------------------------------

resource "random_password" "db" {
  length  = 24
  special = false
  keepers = {
    putaran = var.putaran_rahasia
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = local.parameter
  description = "Password database koma-api Modul 05"
  type        = "SecureString"
  value       = random_password.db.result
  key_id      = aws_kms_key.m05.arn

  tags = {
    Name  = "${local.awalan}-db-password"
    peran = "rahasia"
  }
}

# ---------------------------------------------------------------------------
# C.3 — Peran IAM Minimal (Least Privilege) untuk Server API
# ---------------------------------------------------------------------------

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

  tags = {
    Name  = "${local.awalan}-api-role"
    peran = "iam"
  }
}

resource "aws_iam_role_policy" "baca_parameter" {
  name = "baca-parameter"
  role = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = local.arn_parameter
    }]
  })
}

resource "aws_iam_role_policy" "dekripsi" {
  name = "dekripsi-kms-ssm"
  role = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["kms:Decrypt"]
      Resource = aws_kms_key.m05.arn
      Condition = {
        StringEquals = {
          "kms:ViaService" = "ssm.${var.region}.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_instance_profile" "api" {
  name = "${local.awalan}-api"
  role = aws_iam_role.api.name
}

# ---------------------------------------------------------------------------
# C.4 — Security Group Terbatas (HTTP 80 dari /32 Anda, Egress HTTPS 443)
# ---------------------------------------------------------------------------

resource "aws_security_group" "api" {
  name        = "${local.awalan}-api"
  description = "Security group server api m05 terbatas"
  vpc_id      = data.aws_vpc.bawaan.id

  tags = {
    Name  = "${local.awalan}-api"
    peran = "jaringan"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.api.id
  description       = "HTTP 80 hanya dari IP pengembang (/32)"
  cidr_ipv4         = var.cidr_saya
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

#trivy:ignore:AVD-AWS-0104: EC2 di VPC bawaan memerlukan egress HTTPS 443 ke endpoint regional SSM dan KMS AWS.
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.api.id
  description       = "HTTPS 443 keluar untuk memanggil endpoint SSM dan KMS"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# ---------------------------------------------------------------------------
# C.5 — Server API Aman (IMDSv2 Wajib, Disk Terenkripsi, User Data Bersih)
# ---------------------------------------------------------------------------

resource "aws_instance" "api" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.api.id]
  iam_instance_profile        = aws_iam_instance_profile.api.name
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    versi       = var.versi
    region      = var.region
    parameter   = local.parameter
    aplikasi_gz = base64gzip(file("${path.module}/../../app/koma_api.py"))
  })

  depends_on = [
    aws_ssm_parameter.db_password,
    aws_iam_role_policy.baca_parameter,
    aws_iam_role_policy.dekripsi,
  ]

  tags = {
    Name  = "${local.awalan}-api"
    peran = "api"
    versi = var.versi
  }
}

# ---------------------------------------------------------------------------
# C.6 — Bucket S3 Laporan Privat, Terenkripsi KMS, dan Wajib TLS
# ---------------------------------------------------------------------------

#trivy:ignore:AVD-AWS-0089: Bucket log akses S3 terpisah tidak dibuat pada stack sandbox Modul 05.
#trivy:ignore:AVD-AWS-0090: Versioning bucket arsip dibahas di Modul 04; stack m05 berfokus pada privasi dan SSE-KMS.
resource "aws_s3_bucket" "laporan" {
  bucket        = local.bucket
  force_destroy = true

  tags = {
    Name  = "${local.awalan}-laporan"
    peran = "laporan"
  }
}

resource "aws_s3_bucket_public_access_block" "laporan" {
  bucket                  = aws_s3_bucket.laporan.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "laporan" {
  bucket = aws_s3_bucket.laporan.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "laporan" {
  bucket = aws_s3_bucket.laporan.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.m05.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "laporan" {
  bucket     = aws_s3_bucket.laporan.id
  depends_on = [aws_s3_bucket_public_access_block.laporan]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "TolakTanpaTLS"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        "arn:aws:s3:::${local.bucket}",
        "arn:aws:s3:::${local.bucket}/*",
      ]
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}

resource "aws_s3_object" "laporan" {
  bucket       = aws_s3_bucket.laporan.id
  key          = "laporan/pelanggan-contoh.csv"
  content      = "id,nama,kelas_data\n1,Pelanggan Contoh,rahasia\n"
  content_type = "text/csv"

  depends_on = [
    aws_s3_bucket_server_side_encryption_configuration.laporan,
    aws_s3_bucket_policy.laporan,
  ]
}
