# Modul 06 — server legacy warisan kontraktor. Ikuti naskah Bagian B: tulis resource yang SAMA
# PERSIS dengan yang dibuat `koma legacy buat`, lalu impor dengan blok import di impor.tf.

data "aws_vpc" "bawaan" {
  default = true
}

resource "aws_security_group" "legacy" {
  count       = var.pertahankan_legacy ? 1 : 0
  name        = "${local.awalan}-legacy"
  description = "Web lama koma-api (dibuat manual)"
  vpc_id      = data.aws_vpc.bawaan.id

  tags = {
    Name  = "${local.awalan}-legacy"
    peran = "legacy"
  }
}

resource "aws_vpc_security_group_ingress_rule" "legacy_http" {
  count             = var.pertahankan_legacy ? 1 : 0
  security_group_id = aws_security_group.legacy[0].id
  description       = "HTTP dari kantor"
  cidr_ipv4         = var.cidr_saya
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_instance" "legacy" {
  count                  = var.pertahankan_legacy ? 1 : 0
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.legacy[0].id]

  tags = {
    Name  = "${local.awalan}-legacy"
    peran = "legacy"
    versi = "0.9.0"
  }

  lifecycle {
    ignore_changes = [ami, user_data, user_data_base64]
  }
}

resource "aws_vpc_security_group_ingress_rule" "legacy_dari_alb" {
  count                        = var.pertahankan_legacy ? 1 : 0
  security_group_id            = aws_security_group.legacy[0].id
  description                  = "HTTP dari ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}
