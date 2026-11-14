# Modul 04 — Catatan Bukti

Isi berkas ini segera setelah setiap langkah penting, lalu commit bersama `bukti/bukti-m04.json`.
Waktu ditulis dalam WIB. ID bucket, volume, dan instance disalin dari terminal; jangan menulis nomor akun AWS.

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |
| Modul | M04 — Storage dan State sebagai Kode |

---

## Log Langkah

| Langkah | Waktu (WIB) | Perintah | Hasil Singkat |
|---|---|---|---|
| A.1 Bangun Remote State | | `tofu apply` (di `stacks/m00-state`) | Bucket S3 state backend `koma-123450022-tfstate-...` aktif dengan versioning dan enkripsi AES256 |
| B.1 Bangun Stack Data | | `tofu apply` (di `stacks/m04-data`) | Volume EBS `peran=data`, instance `db` privat, bucket arsip `koma-123450022-m04-arsip-...` dengan 2 aturan lifecycle |
| B.2 Generate Versi Objek | | `aws s3 cp ...` & `tofu apply` | Objek laporan di S3 memiliki >= 2 versi (`arsip_berversi`), state di S3 memiliki >= 2 versi (`state_berversi`) |
| C.1 Potret 1 (Aktif) | | `python3 alat/koma.py cek m04 --lokal` | Cek latihan (`state_remote`, `volume_data`, `instance_db`, `bucket_arsip`) dan tugas lulus verifikasi awal |
| C.2 Uji Volume Selamat | | `tofu apply -replace="aws_instance.db"` (di `stacks/m04-data`) | Server `db` diganti dengan ID baru, volume EBS data yang sama tetap terpasang (`volume_selamat` lulus) |
| C.3 Potret 2 (Aktif 2) | | `python3 alat/koma.py cek m04 --lokal` | Cek `volume_selamat` terverifikasi dalam riwayat potret verifier |
| D.1 Pembersihan Stack Data | | `tofu destroy` (di `stacks/m04-data`) | Server db, volume data, dan bucket arsip dihancurkan; bucket remote state tetap dipertahankan |
| E.1 Potret Bersih Akhir | | `python3 alat/koma.py cek m04 --lokal` | Akun bersih dari resource m04, `bersih_akhir` lulus (`Latihan: True`, `Tugas: True`) |

---

## Catatan Bagian B & C: Storage dan State sebagai Kode

- **Remote State Bucket**: `koma-123450022-tfstate-<akun>`
  - Versioning: Enabled
  - Enkripsi: AES256 (SSE-S3)
  - Akses Publik: Diblokir 100%
  - Kunci State: `m04/data.tfstate` (>= 2 versi)
- **Bucket Arsip**: `koma-123450022-m04-arsip-<akun>`
  - Versioning: Enabled
  - Enkripsi: AES256 (SSE-S3)
  - Akses Publik: Diblokir 100%
  - Lifecycle: >= 2 aturan aktif (aturan transisi noncurrent version dan transisi laporan)
  - Prefix Objek: `laporan/ringkasan-harian.json` (>= 2 versi)
- **Volume EBS Data**:
  - Tipe: `gp3`, Enkripsi: Ya (`encrypted = true`)
  - Tag: `Name = koma-123450022-m04-vol-data`, `peran = data`, `stack = m04-data`, `modul = m04`
  - Terpasang ke: Server `db`, `delete_on_termination = false`
- **Instance Database**:
  - Tipe: `t3.micro`, Subnet: Privat
  - Tag: `Name = koma-123450022-m04-db`, `peran = db`, `stack = m04-data`, `modul = m04`
  - IP Publik: Tidak ada (hanya IP privat)

---

## Potret Tugas
- Potret aktif terakhir: `Latihan lulus: True`, `Tugas lulus: True`
- Potret bersih terakhir: kosong (0 instance, 0 volume data, 0 bucket arsip m04, bucket state tetap ada)
