# Modul 03 — Jaringan sebagai Kode: Stack Network (VPC, Subnet Publik/Privat, IGW, Rute)

data "aws_availability_zones" "tersedia" {
  state = "available"
}

resource "aws_vpc" "utama" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "koma-${var.nim}-m03-vpc"
    stack = "m03-network"
    modul = "m03"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.utama.id

  tags = {
    Name  = "koma-${var.nim}-m03-igw"
    stack = "m03-network"
    modul = "m03"
  }
}

# ---------------------------------------------------------------------------
# Subnet Publik (minimal 2 di 2 AZ berbeda)
# ---------------------------------------------------------------------------

resource "aws_subnet" "publik" {
  count                   = 2
  vpc_id                  = aws_vpc.utama.id
  cidr_block              = cidrsubnet(var.cidr_vpc, 8, count.index + 1) # 10.1.1.0/24, 10.1.2.0/24
  availability_zone       = data.aws_availability_zones.tersedia.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name  = "koma-${var.nim}-m03-sub-pub-${count.index + 1}"
    tier  = "publik"
    stack = "m03-network"
    modul = "m03"
  }
}

# ---------------------------------------------------------------------------
# Subnet Privat (minimal 2 di 2 AZ berbeda, tanpa IP publik otomatis)
# ---------------------------------------------------------------------------

resource "aws_subnet" "privat" {
  count                   = 2
  vpc_id                  = aws_vpc.utama.id
  cidr_block              = cidrsubnet(var.cidr_vpc, 8, (count.index + 1) * 10) # 10.1.10.0/24, 10.1.20.0/24
  availability_zone       = data.aws_availability_zones.tersedia.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name  = "koma-${var.nim}-m03-sub-priv-${count.index + 1}"
    tier  = "privat"
    stack = "m03-network"
    modul = "m03"
  }
}

# ---------------------------------------------------------------------------
# Tabel Rute Publik (0.0.0.0/0 -> IGW)
# ---------------------------------------------------------------------------

resource "aws_route_table" "publik" {
  vpc_id = aws_vpc.utama.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name  = "koma-${var.nim}-m03-rt-pub"
    stack = "m03-network"
    modul = "m03"
  }
}

resource "aws_route_table_association" "publik" {
  count          = 2
  subnet_id      = aws_subnet.publik[count.index].id
  route_table_id = aws_route_table.publik.id
}

# ---------------------------------------------------------------------------
# Tabel Rute Privat (tanpa rute keluar internet, tanpa NAT Gateway)
# ---------------------------------------------------------------------------

resource "aws_route_table" "privat" {
  vpc_id = aws_vpc.utama.id

  tags = {
    Name  = "koma-${var.nim}-m03-rt-priv"
    stack = "m03-network"
    modul = "m03"
  }
}

resource "aws_route_table_association" "privat" {
  count          = 2
  subnet_id      = aws_subnet.privat[count.index].id
  route_table_id = aws_route_table.privat.id
}
