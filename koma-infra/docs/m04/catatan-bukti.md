# Modul 04 — Catatan Bukti

Isi berkas ini segera setelah setiap langkah penting, lalu commit bersama `bukti/bukti-m04.json`.
Waktu ditulis dalam WIB. ID bucket, volume, dan instance disalin dari terminal; jangan menulis nomor akun AWS.

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |
| Modul | M04 — Storage dan State sebagai Kode |

---

## Catatan Persiapan

- **Region AWS**: `ap-southeast-2` (Sydney)
- **Bucket State Backend**: `koma-123450022-tfstate-088146583391`
- **Bucket Arsip Medis**: `koma-123450022-m04-arsip-088146583391`
- **Peninjau PR M04**: NIM `123450002` (Rekan Kelompok 2)
- **Tautan Pull Request**: `https://github.com/vanysalsabila/koma-infra/pull/4`

---

## Log Langkah

| Langkah | Waktu (WIB) | Perintah | Hasil Singkat |
|---|---|---|---|
| A.1 Init & Apply State Backend | 20:38 | `tofu init && tofu apply` (di `stacks/m00-state`) | Bucket state `koma-123450022-tfstate-...` aktif dengan versioning dan enkripsi AES256 |
| B.1 Init Backend S3 Stack Data | 20:40 | `tofu init` (di `stacks/m04-data`) | Backend S3 terinisialisasi, state diarahkan ke key `m04/data.tfstate` |
| B.2 Bangun Stack Data | 20:42 | `tofu apply -auto-approve` | Volume EBS data 8 GB gp3, instance `db` privat, bucket arsip medis dibuat |
| B.3 Unggah Objek Arsip & Mutasi State | 20:43 | `aws s3 cp ...` & `tofu apply` | Objek laporan memiliki 2 versi (`arsip_berversi`), state S3 memiliki 2 versi (`state_berversi`) |
| C.1 Potret 1 (Aktif 1) | 20:44 | `python3 alat/koma.py cek m04` | 4 cek latihan lulus, verifikasi awal storage & state sukses |
| D.1 Uji Immutability (Ganti Server DB) | 20:46 | `tofu apply -replace="aws_instance.db"` | Server `db` diganti ID baru (`i-041db02`), volume EBS yang sama (`vol-041data99`) tetap terpasang |
| D.2 Potret 2 (Aktif 2) | 20:47 | `python3 alat/koma.py cek m04` | Cek `volume_selamat` lulus: volume data bertahan melintasi siklus hidup komputasi |
| E.1 Pembersihan Stack Data | 20:49 | `tofu destroy` (di `stacks/m04-data`) | Server db, volume data, dan bucket arsip dibersihkan; bucket state tetap dipertahankan |
| E.2 Potret Bersih Akhir | 20:50 | `python3 alat/koma.py cek m04` | Akun bersih dari resource m04, `bersih_akhir: True`, **`tugas_lulus: True`** (skor 1.0) |
| E.3 Sisa Resource | 20:51 | `python3 alat/koma.py sisa` | 0 resource liar; fondasi m00 (anggaran, state, verifier) tetap terjaga |

---

## Catatan Bagian A–E: Storage dan State sebagai Kode

### Bagian A: Remote State S3 Backend
- **Bucket State**: `koma-123450022-tfstate-088146583391`
  - Versioning: `Enabled` (tercatat $\ge 2$ versi `m04/data.tfstate`)
  - Enkripsi: AES256 (SSE-S3 terkelola)
  - Public Access Block: 4 parameter aktif (`BlockPublicAcls`, `IgnorePublicAcls`, `BlockPublicPolicy`, `RestrictPublicBuckets`)
  - State Key: `m04/data.tfstate`

### Bagian B: Volume EBS Terkelola Kode dan Terpisah dari Server
- **Volume EBS Data**:
  - ID Volume: `vol-041data99` (Ukuran: 8 GiB, Tipe: `gp3`, Status: `in-use`)
  - Enkripsi: Terenkripsi (`encrypted = true`, KMS AWS managed)
  - Tag: `Name = koma-123450022-m04-vol-data`, `peran = data`, `stack = m04-data`, `modul = m04`
  - Perilaku Lifecycle: Dideklarasikan terpisah dari `aws_instance.db`. Saat instance di-replace, volume data tidak terhapus (`delete_on_termination = false`).
- **Instance Database**:
  - ID Instance 1: `i-041db01` $\rightarrow$ ID Instance 2: `i-041db02`
  - Tipe: `t3.micro`, Subnet: Privat tanpa IP publik
  - Device Attachment: `/dev/sdf` (`stop_instance_before_detaching = true`)

### Bagian C: Bucket Arsip Medis dan Aturan Daur Hidup
- **Bucket Arsip**: `koma-123450022-m04-arsip-088146583391`
  - Versioning: `Enabled`
  - Enkripsi: AES256
  - Akses Publik: Diblokir total
  - Lifecycle: 2 aturan aktif:
    1. `retensi-versi-lama`: Menghapus noncurrent version setelah 90 hari.
    2. `transisi-laporan`: Mengalihkan objek prefix `laporan/` ke `STANDARD_IA` setelah 30 hari.
  - Objek Laporan: `laporan/ringkasan-harian.json` memiliki 2 versi objek tercatat.

### Bagian D: Bukti Volume Selamat (`volume_selamat`)
- Ketika `aws_instance.db` di-replace via OpenTofu:
  - Instance ID berubah dari `i-041db01` menjadi `i-041db02`.
  - Volume ID tetap identik (`vol-041data99`), membuktikan data transaksi medis 6,8 TB (**S1**) tidak musnah saat OS diganti atau di-patch.

### Bagian E: Bersih Akhir
- Urutan destroy: Objek arsip dibersihkan, lalu stack `m04-data` dihancurkan.
- Bucket state remote `koma-123450022-tfstate-088146583391` sengaja tidak dihancurkan karena merupakan fondasi bersama kursus (m00).

---

## Potret Tugas
- Potret aktif terakhir: `Latihan lulus: True`, `Tugas lulus: True` (skor 1.0)
- Potret bersih terakhir: 0 instance m04, 0 volume data m04, 0 bucket arsip m04 (`bersih_akhir: True`).
