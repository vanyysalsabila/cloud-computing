# Modul 06 — versi baru (hijau). Ikuti naskah Bagian C.

data "aws_caller_identity" "saya" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_subnets" "bawaan" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.bawaan.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

locals {
  awalan    = "koma-${var.nim}-m06"
  akun      = data.aws_caller_identity.saya.account_id
  log_group = "/koma/${var.nim}/m06/api"
}

# ---------------------------------------------------------------------------
# C.1 — Security Group Server Hijau (Hanya HTTP 80 dari ALB, Egress 443)
# ---------------------------------------------------------------------------

resource "aws_security_group" "hijau" {
  name        = "${local.awalan}-hijau"
  description = "Security group server hijau koma-api"
  vpc_id      = data.aws_vpc.bawaan.id

  tags = {
    Name  = "${local.awalan}-hijau"
    peran = "hijau"
  }
}

resource "aws_vpc_security_group_ingress_rule" "hijau_dari_alb" {
  security_group_id            = aws_security_group.hijau.id
  description                  = "HTTP 80 hanya dari ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "hijau_https" {
  security_group_id = aws_security_group.hijau.id
  description       = "HTTPS 443 keluar untuk dnf dan CloudWatch Logs"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# ---------------------------------------------------------------------------
# C.2 — Peran IAM Server Hijau (Hanya Menulis Log ke Log Group m06)
# ---------------------------------------------------------------------------

resource "aws_iam_role" "hijau" {
  name = "${local.awalan}-hijau"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name  = "${local.awalan}-hijau-role"
    peran = "hijau"
  }
}

resource "aws_iam_role_policy" "tulis_log" {
  name = "tulis-log-cloudwatch"
  role = aws_iam_role.hijau.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
      ]
      Resource = [
        aws_cloudwatch_log_group.api.arn,
        "${aws_cloudwatch_log_group.api.arn}:*",
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "hijau" {
  name = "${local.awalan}-hijau"
  role = aws_iam_role.hijau.name
}

# ---------------------------------------------------------------------------
# C.3 — Server Hijau (koma-api 6.0.0, IMDSv2, Root Terenkripsi, CW Agent)
# ---------------------------------------------------------------------------

resource "aws_instance" "hijau" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.bawaan.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.hijau.id]
  iam_instance_profile        = aws_iam_instance_profile.hijau.name
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

  user_data = templatefile("${path.module}/templates/cloud-init-hijau.yaml.tftpl", {
    versi       = var.versi_hijau
    log_group   = local.log_group
    aplikasi_gz = base64gzip(file("${path.module}/../../app/koma_api.py"))
  })

  depends_on = [
    aws_cloudwatch_log_group.api,
    aws_iam_role_policy.tulis_log,
  ]

  tags = {
    Name  = "${local.awalan}-hijau"
    peran = "hijau"
    versi = var.versi_hijau
  }
}
