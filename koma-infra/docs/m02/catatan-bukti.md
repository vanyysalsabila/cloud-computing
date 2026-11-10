# Modul 02 — Catatan Bukti

Isi berkas ini segera setelah setiap langkah penting, lalu commit bersama `bukti/bukti-m02.json`.
Waktu ditulis dalam WIB. ID instance dan AMI disalin dari terminal; jangan menulis nomor akun AWS.

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

---

## Log Langkah

| Langkah | Waktu (WIB) | Perintah | Hasil Singkat |
|---|---|---|---|
| A.1 Cek IP | 13:10 | `python3 alat/koma.py ip` | IP publik terdeteksi sebagai `103.59.45.34/32` untuk security group |
| B.1 Cloud-init | 13:17 | `tofu apply` (target: pembangun) | Instance pembangun `i-03dec46382c343c6b` berjalan dengan AMI AL2023, service `koma-api` aktif (HTTP 200) |
| B.2 Panggang AMI | 13:27 | `tofu apply` (target: ami) | AMI `koma-123450022-m02-api-v1` (`ami-09f29c839d5eb91bc`) selesai dibuat dari instance pembangun |
| B.3 Potret 1 | 13:32 | `python3 alat/koma.py cek m02` | AMI terbit dan pembangun dari AMI publik lulus verifikasi |
| C.1 Luncurkan API | 13:27 | `tofu apply` (target: api) | Instance `koma-123450022-m02-api` (`i-027a8901bae0c640a`, IP `54.206.211.180`) aktif dari AMI sendiri |
| C.2 Uji Endpoint | 13:28 | `curl http://54.206.211.180/health` | Status 200 `{"status": "ok", "peran": "api", "versi": "v1"}` |
| C.3 Potret 2 | 13:32 | `python3 alat/koma.py cek m02` | `api_dari_image`, `api_sehat`, dan `sg_terbatas` lulus (`Latihan lulus: True`) |
| D.1 Alih Versi (v2) | 13:37 | `tofu apply -var versi=v2` | Instance API v2 baru `i-09c97b4992bf0ddbf` (`3.27.146.49`) menggantikan v1 dari AMI `ami-0dcf0d5ea0aaac2a9` (prinsip *immutable server*) |
| D.2 Potret 3 | 13:40 | `python3 alat/koma.py cek m02` | Cek `immutable` dan `versi_cocok` lulus (ID instance berbeda: `i-027a8901bae0c640a` -> `i-09c97b4992bf0ddbf`) |
| E.1 Destroy Bersih | 13:46 | `tofu destroy`, `koma cek m02`, `koma sisa` | Akun bersih, potret 4 kosong (13:50 WIB), `bersih_akhir` lulus (`Latihan lulus: True`, `Tugas lulus: True`) |

---

## Catatan Bagian B & C: Server sebagai Kode & Pemanggangan Image

- **Instance Pembangun**: `koma-123450022-m02-pembangun` (`i-03dec46382c343c6b`)
- **AMI Publik Asal**: Amazon Linux 2023 (`al2023-ami-2023.*-x86_64`)
- **AMI Hasil Panggangan (v1)**: `koma-123450022-m02-api-v1` (`ami-09f29c839d5eb91bc`)
- **Instance API (v1)**: `koma-123450022-m02-api` (`i-027a8901bae0c640a`, AMI: milik sendiri)
- **AMI Hasil Panggangan (v2)**: `koma-123450022-m02-api-v2` (`ami-0dcf0d5ea0aaac2a9`)
- **Instance API (v2)**: `koma-123450022-m02-api` (`i-09c97b4992bf0ddbf`)
- **Security Group**: Port 80 hanya dibuka untuk `var.cidr_saya` (`103.59.45.34/32`), tanpa `0.0.0.0/0`.

---

## Catatan Bagian D: Analisis Kasus (k01 — Klinik Sehat Lampung)

### 1. Pola Deployment: Bake vs. Fry
* **Fry (Konfigurasi saat Boot)**: Memasang dependensi dan aplikasi dari internet setiap kali server baru menyala. Pada KSL, 70 klinik dihubungkan lewat koneksi broadband 20–50 Mbps dengan backup LTE yang tidak stabil (**E2**). Jika server klinik atau API cabang melakukan *fry* saat booting, lonjakan waktu inisialisasi dan kegagalan jaringan luar akan memperlambat penyediaan server baru.
* **Bake (Memanggang Image)**: Seluruh runtime, kode `koma_api.py`, dan service unit dikemas ke dalam AMI/image sebelum rilis. Waktu peluncuran instan (tanpa `dnf install` atau `pip install` saat boot), deterministik, dan imun terhadap gangguan koneksi internet luar. Pilihan ini mendukung target pemulihan KSL ≤ 4 jam (**P6**).

### 2. Container vs. Virtual Machine (VM) untuk Komponen E1
Berdasarkan arsitektur KSL (**E1**) dan kendala tim 14 orang (**E6**):

| Komponen | Pilihan (VM / Container) | Alasan Teknis & Bisnis Kasus |
|---|---|---|
| **API RME & Pendaftaran** | VM (tahap awal M02) lalu Container (M10) | Membutuhkan isolasi ketat dan kestabilan. Menghadapi beban puncak pagi 420 req/s (**O3**). Pilihan awal VM mandiri memudahkan tim kecil mengelola sebelum adopsi cluster. |
| **Database Relasional RME (6,8 TB)** | Virtual Machine (VM) / Baremetal | Tidak cocok untuk ephemeral container. Membutuhkan disk I/O stabil, replikasi asinkron ke Metro (**S1**), dan persistensi data medis 25 tahun (**A2**). |
| **Worker & Antrean Notifikasi** | Container / Serverless | Komponen *stateless* pengirim notifikasi jadwal (**C1**, **C3**) yang mengalami lonjakan beban musiman (30.000 pesan/jam saat pukul 18.00). Sangat ideal untuk skala kontainer horizontal. |
| **Server Cache Klinik (70 lokasi)** | Container lokal (koma-cache) | Ditempatkan di PC klinik dengan resource terbatas untuk menyerap beban lokal saat jaringan pusat lambat. |

### 3. Prinsip Immutable Server
Perubahan versi API dari `v1` ke `v2` dilakukan dengan:
1. Memanggang AMI baru (`koma-123450022-m02-api-v2`).
2. Meluncurkan instance API baru dari AMI tersebut (`i-09c97b4992bf0ddbf` menggantikan `i-027a8901bae0c640a`).
3. Mengalihkan lalu lintas ke instance baru, kemudian memusnahkan instance lama.
Server tidak pernah di-SSH atau di-*patch* manual di tempat (*in-place modification*), menghindari terbentuknya *snowflake server* seperti pada insiden **P5**.

---

## Potret Tugas
- AMI aktif awal: `koma-123450022-m02-api-v1` (`ami-09f29c839d5eb91bc`)
- AMI aktif kedua: `koma-123450022-m02-api-v2` (`ami-0dcf0d5ea0aaac2a9`)
- Potret aktif terakhir: `Latihan lulus: True`, `Tugas lulus: True`
- Potret bersih terakhir: kosong (0 instance, 0 AMI liar, snapshot bersih)
