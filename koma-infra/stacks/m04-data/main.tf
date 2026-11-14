# Modul 04 — Storage dan State sebagai Kode: Stack Data (EBS Persistent, Server DB Privat, S3 Bucket Arsip)

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ---------------------------------------------------------------------------
# S3 Bucket Arsip Medis
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "arsip" {
  bucket        = "koma-${var.nim}-m04-arsip-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name       = "koma-${var.nim}-m04-arsip-${data.aws_caller_identity.current.account_id}"
    nim        = var.nim
    kelompok   = var.kelompok
    managed-by = "opentofu"
    modul      = "m04"
  }
}

resource "aws_s3_bucket_versioning" "arsip" {
  bucket = aws_s3_bucket.arsip.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "arsip" {
  bucket = aws_s3_bucket.arsip.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "arsip" {
  bucket = aws_s3_bucket.arsip.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "arsip" {
  bucket = aws_s3_bucket.arsip.id

  depends_on = [aws_s3_bucket_versioning.arsip]

  rule {
    id     = "retensi-versi-lama"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.retensi_versi_hari
    }
  }

  rule {
    id     = "transisi-laporan"
    status = "Enabled"

    filter {
      prefix = "laporan/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# ---------------------------------------------------------------------------
# Security Group DB
# ---------------------------------------------------------------------------

resource "aws_security_group" "db" {
  name        = "koma-${var.nim}-m04-sg-db"
  description = "SG DB m04"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Akses keluar bebas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "koma-${var.nim}-m04-sg-db"
    peran      = "db"
    nim        = var.nim
    kelompok   = var.kelompok
    managed-by = "opentofu"
    modul      = "m04"
  }
}

# ---------------------------------------------------------------------------
# Server DB Privat
# ---------------------------------------------------------------------------

resource "aws_instance" "db" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.db.id]
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "KOMA-PENANDA: server db m04 aktif versi ${var.versi}" > /dev/console
    echo "KOMA-PENANDA: volume data terpasang pada /dev/sdf" > /dev/console
  EOF

  tags = {
    Name       = "koma-${var.nim}-m04-db"
    peran      = "db"
    nim        = var.nim
    kelompok   = var.kelompok
    managed-by = "opentofu"
    modul      = "m04"
    stack      = "m04-data"
    versi      = var.versi
  }
}

# ---------------------------------------------------------------------------
# Volume EBS Data Independen (Persisten)
# ---------------------------------------------------------------------------

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.db.availability_zone
  size              = var.ukuran_data_gib
  type              = "gp3"
  encrypted         = true

  tags = {
    Name       = "koma-${var.nim}-m04-vol-data"
    peran      = "data"
    nim        = var.nim
    kelompok   = var.kelompok
    managed-by = "opentofu"
    modul      = "m04"
    stack      = "m04-data"
  }
}

resource "aws_volume_attachment" "db_data" {
  device_name                    = "/dev/sdf"
  volume_id                      = aws_ebs_volume.data.id
  instance_id                    = aws_instance.db.id
  stop_instance_before_detaching = true
}
