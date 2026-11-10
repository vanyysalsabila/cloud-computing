# Modul 02 — Virtualisasi dan Server sebagai Kode (cloud-init, AMI panggang, immutable)

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
    Environment=KOMA_VERSI=${var.versi}
    Environment=KOMA_PERAN=api
    ExecStart=/usr/bin/python3 /opt/koma/koma_api.py --port 80
    Restart=always
    RestartSec=3

    [Install]
    WantedBy=multi-user.target
  SERVICE

  override_unit = <<-OVERRIDE
    [Service]
    Environment=KOMA_VERSI=${var.versi}
  OVERRIDE
}

# ---------------------------------------------------------------------------
# Security Group
# ---------------------------------------------------------------------------

resource "aws_security_group" "api" {
  name        = "koma-${var.nim}-m02-api-sg"
  description = "Security group terbatas: HTTP 80 hanya dari IP mahasiswa"

  ingress {
    description = "HTTP dari IP mahasiswa saja"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_saya]
  }

  egress {
    description = "Akses keluar bebas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "koma-${var.nim}-m02-api-sg"
  }
}

# ---------------------------------------------------------------------------
# Instance Pembangun (menggunakan AMI publik AL2023 + cloud-init)
# ---------------------------------------------------------------------------

resource "aws_instance" "pembangun" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.api.id]

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
    Name  = "koma-${var.nim}-m02-pembangun"
    peran = "pembangun"
  }
}

# ---------------------------------------------------------------------------
# Pembuatan AMI (Bake Image dari instance pembangun)
# ---------------------------------------------------------------------------

resource "aws_ami_from_instance" "api" {
  count              = var.buat_image ? 1 : 0
  name               = "koma-${var.nim}-m02-api-${var.versi}"
  source_instance_id = aws_instance.pembangun.id

  # Menunggu service siap sebelum snapshot
  depends_on = [aws_instance.pembangun]

  tags = {
    Name  = "koma-${var.nim}-m02-api-${var.versi}"
    versi = var.versi
    modul = "m02"
  }
}

# ---------------------------------------------------------------------------
# Instance API Production (diluncurkan dari AMI buatan sendiri)
# ---------------------------------------------------------------------------

resource "aws_instance" "api" {
  count                       = (var.buat_image && var.jalankan_api) ? 1 : 0
  ami                         = aws_ami_from_instance.api[0].id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.api.id]

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
      - path: /etc/systemd/system/koma-api.service.d/override.conf
        permissions: "0644"
        encoding: b64
        content: ${base64encode(local.override_unit)}
    runcmd:
      - systemctl daemon-reload
      - systemctl restart koma-api.service
  EOF

  tags = {
    Name  = "koma-${var.nim}-m02-api"
    peran = "api"
    versi = var.versi
  }
}
