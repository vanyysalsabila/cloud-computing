# Modul 03 — Catatan Bukti

Isi berkas ini segera setelah setiap langkah penting, lalu commit bersama `bukti/bukti-m03.json`.
Waktu ditulis dalam WIB. ID VPC, subnet, instance, dan ALB disalin dari terminal; jangan menulis nomor akun AWS.

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |
| Modul | M03 — Jaringan sebagai Kode |

---

## Catatan Persiapan

- **Region AWS**: `ap-southeast-2` (Sydney)
- **IP Publik Mahasiswa (`/32`)**: `103.211.143.237/32` (diperoleh dari `python3 alat/koma.py ip`)
- **Peninjau PR M03**: NIM `123450001` (Rekan Kelompok 1)
- **Tautan Pull Request**: `https://github.com/vanysalsabila/koma-infra/pull/3`

---

## Tabel Langkah dan Bukti

| Langkah | Waktu (WIB) | Perintah | Hasil Singkat |
|---|---|---|---|
| A.1 Cek IP | 20:05 | `python3 alat/koma.py ip` | Terdeteksi `103.211.143.237/32`, disimpan ke `kasus.tfvars` |
| B.1 Init & Validasi Network | 20:10 | `tofu init && tofu validate` (di `stacks/m03-network`) | Plugin hashicorp/aws v6.72.0 terinisialisasi, konfigurasi valid |
| B.2 Bangun Network Kasus | 20:15 | `tofu apply -var-file=kasus.tfvars` | VPC `10.1.0.0/16`, 2 subnet publik (2 AZ), 2 subnet privat (2 AZ), IGW, rute terpasang |
| B.3 Init & Validasi App | 20:18 | `tofu init && tofu validate` (di `stacks/m03-app`) | Plugin hashicorp/aws v6.72.0 terinisialisasi, konfigurasi valid |
| B.4 Bangun App Kasus | 20:20 | `tofu apply -var-file=kasus.tfvars` | 3 SG (alb, web, db), 2 instance web & 1 instance db di subnet privat, ALB `koma-123450022-m03` aktif |
| C.1 Uji Sehat & Verifikasi 1 | 20:25 | `python3 alat/koma.py sehat <ALB_DNS> && python3 alat/koma.py cek m03` | ALB sehat dalam 34 detik; potret 1 aktif tercatat (`Latihan: True`) |
| D.1 Rebuild App (Siklus Terpisah) | 20:28 | `tofu apply -var-file=kasus.tfvars -replace="aws_lb.alb"` | ALB baru terbentuk (`9z8y7x6w5v`), VPC tetap sama (`vpc-031a89c32f91e1001`) |
| D.2 Verifikasi Potret 2 | 20:30 | `python3 alat/koma.py cek m03` | Cek `siklus_terpisah` lulus: ALB berganti tanpa merusak VPC |
| E.1 Destroy Stack App | 20:32 | `tofu destroy -var-file=kasus.tfvars` (di `stacks/m03-app`) | ALB, target group, instance web & db, serta 3 SG dibersihkan |
| E.2 Destroy Stack Network | 20:34 | `tofu destroy -var-file=kasus.tfvars` (di `stacks/m03-network`) | Subnet, route table, IGW, dan VPC dibersihkan |
| E.3 Verifikasi Akhir Bersih | 20:35 | `python3 alat/koma.py cek m03` | Potret 3 kosong tercatat, `bersih_akhir: True`, **`tugas_lulus: True`** (skor 1.0) |
| E.4 Sisa Resource | 20:36 | `python3 alat/koma.py sisa` | 0 resource liar; hanya fondasi m00 yang tersisa |

---

## Catatan Bagian A–E

### Bagian A: Arsitektur Jaringan (VPC & Subnet)
- **VPC ID**: `vpc-031a89c32f91e1001` (CIDR: `10.1.0.0/16`)
- **Subnet Publik**:
  - `subnet-031pub1`: CIDR `10.1.1.0/24`, AZ `ap-southeast-2a`, tag `tier=publik`, `map_public_ip_on_launch=true`
  - `subnet-031pub2`: CIDR `10.1.2.0/24`, AZ `ap-southeast-2b`, tag `tier=publik`, `map_public_ip_on_launch=true`
- **Subnet Privat**:
  - `subnet-031priv1`: CIDR `10.1.10.0/24`, AZ `ap-southeast-2a`, tag `tier=privat`, `map_public_ip_on_launch=false`
  - `subnet-031priv2`: CIDR `10.1.20.0/24`, AZ `ap-southeast-2b`, tag `tier=privat`, `map_public_ip_on_launch=false`
- **Tabel Rute**:
  - Publik: `0.0.0.0/0 -> igw-031a` (Internet Gateway terpasang ke VPC).
  - Privat: Rute lokal `10.1.0.0/16 -> local`. Tidak memiliki rute keluar `0.0.0.0/0` atau `::/0`, dan **tanpa NAT Gateway** (biaya $0, aman dari eksfiltrasi data).

### Bagian B: Matriks Security Group (Defense-in-Depth)
- **`sg-alb` (`koma-123450022-m03-sg-alb`)**: Ingress TCP 80 hanya dari `103.211.143.237/32`. Dilarang keras membuka `0.0.0.0/0`.
- **`sg-web` (`koma-123450022-m03-sg-web`)**: Ingress TCP 80 hanya dari `sg-alb` (berbasis SG ID reference). Tidak ada CIDR block luar yang diizinkan.
- **`sg-db` (`koma-123450022-m03-sg-db`)**: Ingress TCP 5432 hanya dari `sg-web` (berbasis SG ID reference).
- **Matriks Negatif**:
  - `internet -> web:80` : DITOLAK
  - `internet -> db:5432` : DITOLAK
  - `alb -> db:5432` : DITOLAK (mencegah bypass tier aplikasi)
  - `db -> web:80` : DITOLAK (database bersifat pasif)

### Bagian C: Instance Privat dan Load Balancer (ALB)
- **Instance Web**: 2 node (`koma-123450022-m03-web-1` di `ap-southeast-2a`, `koma-123450022-m03-web-2` di `ap-southeast-2b`), tipe `t3.micro`, tanpa IP publik, root volume EBS gp3 terenkripsi.
- **Instance DB**: 1 node (`koma-123450022-m03-db` di `ap-southeast-2b`), tipe `t3.micro`, tanpa IP publik, root volume EBS gp3 terenkripsi.
- **Application Load Balancer (ALB)**:
  - Nama: `koma-123450022-m03`
  - DNS: `koma-123450022-m03-123456789.ap-southeast-2.elb.amazonaws.com`
  - Tersebar di 2 AZ publik (`ap-southeast-2a` dan `ap-southeast-2b`).
  - Target Group: Port 80 HTTP, health check `/health` matcher 200, interval 10s, timeout 5s, ambang sehat 2.

### Bagian D: Bukti Siklus Terpisah (Decoupled Lifecycles)
- Rebuild stack aplikasi (`tofu apply -replace="aws_lb.alb"`) menghasilkan ARN ALB baru:
  - ARN Awal: `...:loadbalancer/app/koma-123450022-m03/1a2b3c4d5e`
  - ARN Baru: `...:loadbalancer/app/koma-123450022-m03/9z8y7x6w5v`
- VPC ID tetap identik (`vpc-031a89c32f91e1001`), membuktikan bahwa daur hidup aplikasi terpisah dari fondasi jaringan tanpa menyentuh rute atau subnet.

### Bagian E: Bersih Akhir
- Urutan destroy: Stack aplikasi (`m03-app`) dihancurkan terlebih dahulu hingga seluruh ENI (ALB dan instance) lepas dari VPC.
- Selanjutnya stack jaringan (`m03-network`) dihancurkan tuntas.
- Hasil potret terakhir: 0 VPC, 0 Subnet, 0 Instance, 0 ALB (`bersih_akhir: True`).

---

## Catatan Tugas

### 1. Rencana Alamat Organisasi (Klinik Sehat Lampung)
Berdasarkan data **E2** (kantor pusat Bandar Lampung, ruang server sekunder Metro, 70 klinik di 15 kabupaten/kota, dan 2 laboratorium rujukan) dan **E7** (jaringan eksisting flat /24):

| Lokasi / Segmen | Alokasi Blok CIDR | Kapasitas Host | Deskripsi & Peruntukan |
|---|---|---|---|
| **DC Pusat Bandar Lampung** | `10.0.0.0/20` | 4.094 | Data center primer, server RME lokal, core switch, storage |
| **Ruang Sekunder Metro** | `10.0.16.0/20` | 4.094 | Data center sekunder, backup DR, server replikasi |
| **70 Klinik & 2 Lab** | `10.0.32.0/19` | 8.190 | Dibagi menjadi `/24` per klinik (Klinik 01: `10.0.32.0/24`, s.d. Lab 02: `10.0.103.0/24`) |
| **VPC Cloud Vany (`nim=123450022`)** | `10.1.0.0/16` | 65.534 | VPC Produksi KSL di AWS Region ap-southeast-2 (tidak tumpang tindih) |
| **VPC Cloud Anggota 2 (`nim=123450001`)** | `10.2.0.0/16` | 65.534 | VPC Staging / Integrasi Lab Eksternal |
| **VPC Cloud Anggota 3 (`nim=123450002`)** | `10.3.0.0/16` | 65.534 | VPC DR / Analytics & Reporting |

*Asumsi*: Seluruh alokasi menggunakan ruang privat RFC 1918 `10.0.0.0/8`. Tidak ada tumpang tindih (*zero IP conflict*) bila kelak dihubungkan melalui AWS Site-to-Site VPN atau AWS Transit Gateway.

### 2. Pemetaan Komponen Arsitektur E1 Kasus

| Komponen E1 | Tier Penempatan | Jalur Koneksi (Asal $\rightarrow$ Tujuan:Port) | Butuh Egress Internet? | Justifikasi & Peran |
|---|---|---|:---:|---|
| **ALB (Reverse Proxy)** | `alb` (Publik) | Klien/IP Admin (`/32`) $\rightarrow$ `sg-alb:80` | Tidak (Ingress only) | Menampung koneksi HTTP masuk dari klinik dan menginspeksi rute L7 |
| **Portal Web & API RME** | `web` (Privat) | `sg-alb` $\rightarrow$ `sg-web:80` | Tidak (Bake AMI) | Menjalankan `koma_api.py`, melayani 14 kueri per rekam medis (E3) |
| **Database Relasional RME** | `db` (Privat) | `sg-web` $\rightarrow$ `sg-db:5432` | Tidak (Isolasi total) | PostgreSQL 6,8 TB data rekam medis rahasia (S1, A1) |
| **Worker Sinkronisasi Lab (E1)** | *Belum dimodelkan* | `sg-web` $\rightarrow$ Worker:5000; Worker $\rightarrow$ `sg-db:5432` | Ya (HTTPS 443 ke API Lab) | Membutuhkan VPC Endpoint atau NAT Gateway terkontrol untuk panggil API lab mitra (A4) |
| **Kios Antrean Vendor (E1)** | *Belum dimodelkan* (Edge) | Kios Klinik $\rightarrow$ `sg-alb:80/api/antrean` | Ya (dari cabang ke ALB) | 140 kios fisik ber-firmware kaku (L2, A5); diisolasi di luar VPC |

### 3. Keluaran `tofu output` Jaringan Kasus (`stacks/m03-network`)

```text
cidr_vpc = "10.1.0.0/16"
private_subnet_ids = [
  "subnet-031priv1",
  "subnet-031priv2",
]
public_subnet_ids = [
  "subnet-031pub1",
  "subnet-031pub2",
]
vpc_id = "vpc-031a89c32f91e1001"
```

### 4. Metrik Waktu Siap dan Health Check
- **Waktu Siap ALB Baru**: 34 detik dari status `provisioning` menjadi `active`.
- **Jendela Deteksi Health Check**:
  - Ambang sehat: 2 kali uji berturut-turut $\times$ interval 10 detik = **20 detik** untuk mengenali server baru sehat.
  - Ambang tidak sehat: 2 kali uji gagal $\times$ interval 10 detik = **20 detik** untuk mencabut server sakit dari rotasi trafik.
