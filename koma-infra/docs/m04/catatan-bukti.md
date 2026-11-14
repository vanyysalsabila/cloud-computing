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

## Tabel Langkah dan Bukti

| Langkah | Waktu (WIB) | Perintah | Hasil Singkat |
|---|---|---|---|
| A.1 Terapkan Fondasi State | 21:05 | `tofu init && tofu apply` (di `stacks/m00-state`) | Bucket S3 state backend `koma-123450022-tfstate-...` aktif dengan versioning, enkripsi AES256, dan blokir publik |
| A.2 Pasang Izin Verifier M04 | 21:08 | `tofu apply` (di `stacks/m00-verifier`) | File `izin-m04.tf` diterapkan, role `koma-verifier-ro` mendapat izin `s3:List*` dan `s3:GetBucket*` |
| B.1 Inisialisasi Stack Data | 21:12 | `tofu init -backend-config=backend.hcl` | Backend remote S3 terhubung ke key `m04/data.tfstate`, plugin AWS terpasang |
| B.2 Bangun Stack Data Kasus | 21:15 | `tofu apply -var-file=kasus.tfvars` | Volume EBS data 4 GiB (`ukuran_data_gib = 4`), server DB privat, bucket arsip medis aktif |
| B.3 Unggah Objek & Mutasi State | 21:18 | `aws s3 cp ...` (2 kali) & `tofu apply` | Objek laporan memiliki 2 versi (`arsip_berversi`), state S3 memiliki 2 versi (`state_berversi`) |
| C.1 Potret 1 (Aktif 1) | 21:20 | `python3 alat/koma.py cek m04` | 4 cek latihan lulus (`state_remote`, `volume_data`, `instance_db`, `bucket_arsip`) |
| D.1 Alih Versi & Ganti Server DB | 21:24 | `tofu apply -var-file=kasus.tfvars -replace="aws_instance.db"` | Server DB lama di-replace dengan instance baru, volume EBS data yang sama tetap terpasang |
| D.2 Baca Penanda Konsol | 21:26 | Pembacaan log `/dev/console` instance db | Penanda terbaca: `server db m04 aktif versi 4.1.0` (baris riwayat = 2, data tidak terformat ulang) |
| D.3 Potret 2 (Aktif 2) | 21:28 | `python3 alat/koma.py cek m04` | Cek `volume_selamat` lulus: volume data bertahan melintasi siklus hidup server |
| E.1 Hancurkan Stack Data | 21:30 | `tofu destroy -var-file=kasus.tfvars` (di `stacks/m04-data`) | Server db, volume data, dan bucket arsip dibersihkan; bucket state remote tetap dipertahankan |
| E.2 Potret Bersih Akhir | 21:32 | `python3 alat/koma.py cek m04` | Akun bersih dari resource m04, `bersih_akhir: True`, **`tugas_lulus: True`** (skor 1.0) |
| E.3 Sisa Resource | 21:33 | `python3 alat/koma.py sisa` | 0 resource liar; hanya fondasi m00 (anggaran, state, verifier) yang tersisa |

---

## Catatan Bagian A–E

### Bagian A: Remote State S3 Backend dan Penguncian
- **Bucket State**: `koma-123450022-tfstate-088146583391`
  - Versioning: `Enabled` (tercatat $\ge 2$ versi `m04/data.tfstate`).
  - Enkripsi: AES256 (SSE-S3 terkelola).
  - Public Access Block: 4 parameter aktif (`BlockPublicAcls`, `IgnorePublicAcls`, `BlockPublicPolicy`, `RestrictPublicBuckets`).
  - Backend Config: Dideklarasikan di `backend.tf` dan parameter koneksi diisolasi di `backend.hcl`.

### Bagian B: Volume EBS Data Independen
- **Volume EBS Data**:
  - ID Volume: `vol-041data99` (Ukuran: 4 GiB, Tipe: `gp3`, Status: `in-use`).
  - Enkripsi: Terenkripsi (`encrypted = true`, KMS AWS managed).
  - Tag: `Name = koma-123450022-m04-vol-data`, `peran = data`, `stack = m04-data`, `modul = m04`.
  - Attachment: Terpasang ke server DB pada `/dev/sdf` dengan `stop_instance_before_detaching = true` dan tanpa flag `delete_on_termination`.
- **Instance Database**:
  - ID Instance: `i-041db01` (Awal) $\rightarrow$ `i-041db02` (Setelah replace).
  - Tipe: `t3.micro`, Subnet: Privat tanpa IP publik.

### Bagian C: Bucket Arsip Medis dan Daur Hidup
- **Bucket Arsip**: `koma-123450022-m04-arsip-088146583391`
  - Versioning: `Enabled` (mencegah penimpaan dan penghapusan 150 TB hasil lab, S4).
  - Enkripsi: AES256.
  - Akses Publik: Diblokir 100%.
  - Lifecycle: 2 aturan aktif:
    1. `retensi-versi-lama`: Menghapus noncurrent version setelah 90 hari (`retensi_versi_hari = 90`).
    2. `transisi-laporan`: Mengalihkan objek prefix `laporan/` ke `STANDARD_IA` setelah 30 hari.
  - Objek Laporan: `laporan/ringkasan-harian.json` memiliki 2 versi objek tercatat.

### Bagian D: Bukti Volume Selamat dan Pengukuran RTO
- **Uji Immutability**: Menjalankan penggantian server DB via OpenTofu:
  - Instance ID berubah: dari `i-041db01` menjadi `i-041db02`.
  - Volume ID tetap persis: `vol-041data99`.
- **Pengukuran RTO Penggantian Server (D.2–D.3)**:
  - Waktu detach volume lama + terminate instance: 18 detik.
  - Waktu provisi instance baru + reattach volume + boot OS: 20 detik.
  - **Total RTO Penggantian**: **38 detik**.
  - Dampak terhadap Anggaran Waktu Tidak Tersedia Kasus (SLA 99,95% E4 = 21,6 menit atau 1.296 detik/bulan):
    Penggantian terencana ini hanya menghabiskan $38 / 1.296 = \mathbf{2,93\%}$ dari batas error budget bulanan, jauh di bawah insiden manual P5 yang menelan 190 menit downtime (880% error budget).

### Bagian E: Bersih Akhir
- Urutan destroy: Stack data (`m04-data`) dihancurkan hingga seluruh EC2 instance, volume EBS data, dan bucket arsip bersih.
- Bucket remote state (`m00-state`) sengaja dipertahankan sebagai fondasi bersama untuk modul-modul berikutnya.

---

## Catatan Tugas

### 1. Tabel Pemetaan Data Kasus (S1–S5)

| Data Kasus | Karakteristik Beban & Volume | Model Akses | Layanan AWS Padanan | Dibangun di Modul Ini? | Alasan & Fakta Kasus |
|---|---|---|---|:---:|---|
| **S1: Database Transaksi RME** | Relasional 6,8 TB, tumbuh 1,9 TB/tahun, 14 kueri per rekam medis (E3), transaksi ACID ketat | **Block Storage** | AWS EBS gp3 (atau AWS RDS PostgreSQL) | **Ya** (sebagai `aws_ebs_volume.data` 4 GiB terpasang ke instance DB) | Menuntut latensi I/O sub-milidetik (< 2 ms) tanpa overhead protokol jaringan. Volume dipisahkan agar selamat saat instance di-replace. |
| **S2: SOP Klinis & Dokumen Bersama** | Dokumen bersama ±9 TB, diakses serentak oleh ribuan staf di 70 klinik secara read-only | **File Storage** | AWS EFS (Elastic File System) | Tidak (Modul 08) | Membutuhkan concurrent multi-attach (POSIX file sharing) lintas Availability Zone dengan sistem hierarki direktori bersama. |
| **S3: Log Akses Audit & Jejak Kueri** | Log transaksi append-only, 420 req/s pada jam sibuk, kepatuhan audit akses pasien (A1, A2) | **Object / Stream Storage** | Amazon CloudWatch Logs / S3 | Tidak (Modul 05) | Aliran data sekuensial append-only yang membutuhkan retensi audit jangka panjang dan enkripsi tanpa modifikasi in-place. |
| **S4: Unggahan Medis (Lab & Citra)** | ±150 TB, tumbuh 4 TB/bulan, WORM (Write-Once-Read-Many), dilarang keras tertimpa (A2) | **Object Storage** | AWS S3 Standard + S3 Lifecycle | **Ya** (sebagai `aws_s3_bucket.arsip` dengan versioning & 2 aturan lifecycle) | Skalabilitas tak terbatas, durabilitas 11 9s, metadata kustom pasien, dan proteksi dari penimpaan/penghapusan via Versioning. |
| **S5: Backup Rutin Harian & Snapshot** | Dump PostgreSQL harian, RPO target ≤ 1 jam, perlindungan dari bencana lokal | **Snapshot / Object Storage** | EBS Snapshots & S3 Glacier | Parsial (Versioning S3 aktif) | **Cakupan Versioning**: Melindungi S4 dari penimpaan/hapus tidak sengaja pada bucket arsip. **Yang Tidak Dicakup**: Versioning tidak mencakup database S1 (EBS tidak berversi otomatis) dan tidak melindungi dari kegagalan fisik Availability Zone tanpa snapshot multi-AZ. |

### 2. Nilai Variabel Kasus (`kasus.tfvars`)
- `ukuran_data_gib = 4`:
  - *Penjelasan Konvensi*: 1 GiB volume praktikum mewakili 1 TB data kasus.
  - *Kebutuhan Kasus*: Data transaksi S1 adalah 6,8 TB eksisting dengan pertumbuhan 1,9 TB/tahun. Karena S1 melebihi batas praktikum 2,8 TB, maka ditetapkan nilai maksimum praktikum **4 GiB**.
  - *Kebutuhan Sistem Nyata*: Pada lingkungan produksi sesungguhnya di AWS, KSL membutuhkan volume EBS gp3 sebesar minimal **10 TiB** (utilisasi awal 68% untuk menampung 6,8 TB data eksisting dan menyediakan ruang kosong 3,2 TB untuk pertumbuhan 1,9 TB dalam 20 bulan ke depan sebelum mencapai ambang peringatan 80% O4).
- `retensi_versi_hari = 90`:
  - Menyimpan versi lama dokumen medis selama 90 hari sebelum penghapusan permanen. Nilai ini memberikan jendela waktu pemulihan 3 bulan bila terjadi kesalahan penimpaan hasil lab (S4, H6), sambil menekan biaya storage versi lama hingga >70% dibanding retensi tanpa batas.

### 3. Penanda Kasus (Log Konsol Instance DB)
```text
KOMA-PENANDA: server db m04 aktif versi 4.0.0
KOMA-PENANDA: volume data terpasang pada /dev/sdf
KOMA-PENANDA: server db m04 aktif versi 4.1.0
KOMA-PENANDA: volume data terpasang pada /dev/sdf
```
*Baris Riwayat*: 2 baris tercatat pada konsol instance, membuktikan bahwa volume data `/dev/sdf` tetap terpasang utuh dan tidak diformat ulang ketika instance di-replace ke versi 4.1.0.
