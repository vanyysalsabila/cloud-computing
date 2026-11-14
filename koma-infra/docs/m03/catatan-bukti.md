# Modul 03 — Catatan Bukti

Isi berkas ini segera setelah setiap langkah penting, lalu commit bersama `bukti/bukti-m03.json`.
Waktu ditulis dalam WIB. ID VPC, subnet, instance, dan ALB disalin dari terminal; jangan menulis nomor akun AWS.

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |
| Modul | M03 — Jaringan sebagai Kode |

---

## Log Langkah

| Langkah | Waktu (WIB) | Perintah | Hasil Singkat |
|---|---|---|---|
| A.1 Cek IP | | `python3 alat/koma.py ip` | IP publik terdeteksi sebagai `/32` untuk ingress security group ALB |
| B.1 Bangun Jaringan | | `tofu apply` (di `stacks/m03-network`) | VPC `10.1.0.0/16`, 2 subnet publik di 2 AZ, 2 subnet privat di 2 AZ, IGW, dan tabel rute terpasang |
| B.2 Bangun Aplikasi | | `tofu apply` (di `stacks/m03-app`) | SG `alb`, `web`, `db`, instance `web` dan `db` privat, ALB `koma-123450022-m03` aktif dengan target sehat |
| C.1 Potret 1 (Aktif) | | `python3 alat/koma.py cek m03 --lokal` | Seluruh 7 cek latihan dan cek tugas lulus verifikasi awal |
| C.2 Uji Siklus Terpisah | | `tofu apply -replace="aws_lb.alb"` (di `stacks/m03-app`) | Stack app dibangun ulang (ALB baru) pada VPC yang sama (`siklus_terpisah` lulus) |
| C.3 Potret 2 (Aktif 2) | | `python3 alat/koma.py cek m03 --lokal` | Cek `siklus_terpisah` terverifikasi dalam riwayat potret |
| D.1 Destroy Stack App | | `tofu destroy` (di `stacks/m03-app`) | Instance, ALB, dan SG aplikasi dibersihkan, VPC tetap hidup |
| D.2 Destroy Stack Network | | `tofu destroy` (di `stacks/m03-network`) | VPC, subnet, dan IGW dibersihkan tuntas |
| E.1 Potret Bersih Akhir | | `python3 alat/koma.py cek m03 --lokal` | Akun bersih (0 VPC, 0 instance, 0 ALB), `bersih_akhir` lulus (`Latihan: True`, `Tugas: True`) |

---

## Catatan Bagian B & C: Jaringan sebagai Kode

- **VPC ID**: `koma-123450022-m03-vpc` (CIDR: `10.1.0.0/16`)
- **Subnet Publik**:
  - `koma-123450022-m03-sub-pub-1` (`10.1.1.0/24`, AZ: `ap-southeast-2a`, tag `tier=publik`)
  - `koma-123450022-m03-sub-pub-2` (`10.1.2.0/24`, AZ: `ap-southeast-2b`, tag `tier=publik`)
- **Subnet Privat**:
  - `koma-123450022-m03-sub-priv-1` (`10.1.10.0/24`, AZ: `ap-southeast-2a`, tag `tier=privat`, tanpa IP publik otomatis)
  - `koma-123450022-m03-sub-priv-2` (`10.1.20.0/24`, AZ: `ap-southeast-2b`, tag `tier=privat`, tanpa IP publik otomatis)
- **Tabel Rute**:
  - Publik: `0.0.0.0/0 -> igw`
  - Privat: tanpa rute keluar (tanpa NAT Gateway, hemat biaya dan imun dari koneksi luar)
- **Security Group**:
  - `koma-123450022-m03-sg-alb` (tag `peran=alb`): Ingress TCP 80 hanya dari IP `/32` mahasiswa
  - `koma-123450022-m03-sg-web` (tag `peran=web`): Ingress TCP 80 hanya dari `sg-alb`
  - `koma-123450022-m03-sg-db` (tag `peran=db`): Ingress TCP 5432 hanya dari `sg-web`
- **Instance Privat**:
  - `koma-123450022-m03-web`: Subnet privat, tanpa IP publik, SG web, melayani `/health`
  - `koma-123450022-m03-db`: Subnet privat, tanpa IP publik, SG db
- **Application Load Balancer**:
  - Nama: `koma-123450022-m03`, tersebar di 2 subnet publik (2 AZ), target group sehat pada instance web

---

## Potret Tugas
- Potret aktif terakhir: `Latihan lulus: True`, `Tugas lulus: True`
- Potret bersih terakhir: kosong (0 VPC m03, 0 instance, 0 ALB, snapshot bersih)
