# Modul 06 — satu alamat untuk dua versi. Ikuti naskah Bagian C.

# ---------------------------------------------------------------------------
# C.4 — Security Group ALB
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.awalan}-alb"
  description = "Security group Application Load Balancer m06"
  vpc_id      = data.aws_vpc.bawaan.id

  tags = {
    Name  = "${local.awalan}-alb"
    peran = "alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP 80 dari IP pengembang (/32)"
  cidr_ipv4         = var.cidr_saya
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_ke_vpc" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP 80 keluar menuju target di VPC bawaan"
  cidr_ipv4         = data.aws_vpc.bawaan.cidr_block
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# ---------------------------------------------------------------------------
# C.5 — Application Load Balancer & Target Group Biru / Hijau
# ---------------------------------------------------------------------------

resource "aws_lb" "api" {
  name               = local.awalan
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.bawaan.ids

  tags = {
    Name  = local.awalan
    peran = "alb"
  }
}

resource "aws_lb_target_group" "biru" {
  count                = var.pertahankan_legacy ? 1 : 0
  name                 = "${local.awalan}-biru"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.bawaan.id
  deregistration_delay = 5

  health_check {
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name  = "${local.awalan}-biru"
    peran = "biru"
  }
}

resource "aws_lb_target_group_attachment" "biru" {
  count            = var.pertahankan_legacy ? 1 : 0
  target_group_arn = aws_lb_target_group.biru[0].arn
  target_id        = aws_instance.legacy[0].id
  port             = 80
}

resource "aws_lb_target_group" "hijau" {
  name                 = "${local.awalan}-hijau"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.bawaan.id
  deregistration_delay = 5

  health_check {
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name  = "${local.awalan}-hijau"
    peran = "hijau"
  }
}

resource "aws_lb_target_group_attachment" "hijau" {
  target_group_arn = aws_lb_target_group.hijau.arn
  target_id        = aws_instance.hijau.id
  port             = 80
}

# ---------------------------------------------------------------------------
# C.6 — Listener Port 80 dan Pemilihan Target Group Aktif
# ---------------------------------------------------------------------------

locals {
  tg_aktif = var.aktif == "hijau" ? aws_lb_target_group.hijau.arn : try(aws_lb_target_group.biru[0].arn, "")
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = local.tg_aktif
  }

  lifecycle {
    precondition {
      condition     = var.aktif == "hijau" || var.pertahankan_legacy
      error_message = "Tidak dapat mengarahkan lalu lintas ke biru ketika pertahankan_legacy = false (legacy sudah dibongkar)."
    }
  }
}
