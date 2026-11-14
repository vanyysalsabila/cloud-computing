# Modul 03 — Jaringan sebagai Kode: Stack Aplikasi (SG alb/web/db, Instance Privat, ALB)

data "aws_vpc" "utama" {
  filter {
    name   = "tag:modul"
    values = ["m03"]
  }
  filter {
    name   = "tag:nim"
    values = [var.nim]
  }
}

data "aws_subnets" "publik" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.utama.id]
  }
  filter {
    name   = "tag:tier"
    values = ["publik"]
  }
}

data "aws_subnets" "privat" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.utama.id]
  }
  filter {
    name   = "tag:tier"
    values = ["privat"]
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

locals {
  service_unit = <<-SERVICE
    [Unit]
    Description=koma-api service
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    Environment=KOMA_VERSI=v1
    Environment=KOMA_PERAN=web
    ExecStart=/usr/bin/python3 /opt/koma/koma_api.py --port 80
    Restart=always
    RestartSec=3

    [Install]
    WantedBy=multi-user.target
  SERVICE
}

# ---------------------------------------------------------------------------
# Security Groups (Tiga SG: alb, web, db)
# ---------------------------------------------------------------------------

# 1. SG ALB: Port 80 hanya dari IP komputer mahasiswa (/32)
resource "aws_security_group" "alb" {
  name        = "koma-${var.nim}-m03-sg-alb"
  description = "SG ALB: HTTP 80 hanya dari IP komputer mahasiswa"
  vpc_id      = data.aws_vpc.utama.id

  ingress {
    description = "HTTP dari IP mahasiswa"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_saya]
  }

  egress {
    description = "Akses keluar bebas ke target"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "koma-${var.nim}-m03-sg-alb"
    peran = "alb"
    stack = "m03-app"
    modul = "m03"
  }
}

# 2. SG Web: Port 80 hanya dari SG ALB (tidak ada CIDR eksternal)
resource "aws_security_group" "web" {
  name        = "koma-${var.nim}-m03-sg-web"
  description = "SG Web: Port 80 hanya dari SG ALB"
  vpc_id      = data.aws_vpc.utama.id

  ingress {
    description     = "HTTP dari ALB saja"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Akses keluar bebas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "koma-${var.nim}-m03-sg-web"
    peran = "web"
    stack = "m03-app"
    modul = "m03"
  }
}

# 3. SG DB: Port 5432 hanya dari SG Web (tidak ada CIDR eksternal)
resource "aws_security_group" "db" {
  name        = "koma-${var.nim}-m03-sg-db"
  description = "SG DB: Port 5432 hanya dari SG Web"
  vpc_id      = data.aws_vpc.utama.id

  ingress {
    description     = "PostgreSQL dari tier Web saja"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Akses keluar bebas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "koma-${var.nim}-m03-sg-db"
    peran = "db"
    stack = "m03-app"
    modul = "m03"
  }
}

# ---------------------------------------------------------------------------
# Server / Instance di Subnet Privat (Tanpa IP Publik)
# ---------------------------------------------------------------------------

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = tolist(data.aws_subnets.privat.ids)[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  user_data = <<-EOF
    #cloud-config
    write_files:
      - path: /opt/koma/koma_api.py
        permissions: "0755"
        encoding: b64
        content: ${base64encode(file("${path.module}/../../app/koma_api.py"))}
      - path: /etc/systemd/system/koma-api.service
        permissions: "0644"
        encoding: b64
        content: ${base64encode(local.service_unit)}
    runcmd:
      - systemctl daemon-reload
      - systemctl enable --now koma-api.service
  EOF

  tags = {
    Name  = "koma-${var.nim}-m03-web"
    peran = "web"
    stack = "m03-app"
    modul = "m03"
  }
}

resource "aws_instance" "db" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = tolist(data.aws_subnets.privat.ids)[1]
  vpc_security_group_ids      = [aws_security_group.db.id]
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name  = "koma-${var.nim}-m03-db"
    peran = "db"
    stack = "m03-app"
    modul = "m03"
  }
}

# ---------------------------------------------------------------------------
# Application Load Balancer (ALB) di Subnet Publik
# ---------------------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "koma-${var.nim}-m03"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.publik.ids

  tags = {
    Name  = "koma-${var.nim}-m03"
    stack = "m03-app"
    modul = "m03"
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "koma-${var.nim}-m03-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.utama.id
  target_type = "instance"

  health_check {
    path                = "/health"
    port                = "80"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name  = "koma-${var.nim}-m03-tg"
    stack = "m03-app"
    modul = "m03"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
