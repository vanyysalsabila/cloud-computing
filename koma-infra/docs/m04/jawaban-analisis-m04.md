# Jawaban Analisis — Modul 04: Storage dan State sebagai Kode

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |
| Tanggal | 14 November 2026 |

---

## Pertanyaan 1 — Taksonomi dan Pemilihan Tipe Penyimpanan (Block vs. File vs. Object)

**Pertanyaan:**
Berdasarkan Evidence Pack **S1**, **S2**, dan **S4**, evaluasi karakteristik kebutuhan penyimpanan data Klinik Sehat Lampung. Tentukan klasifikasi tipe penyimpanan (*Block*, *File*, atau *Object Storage*) yang paling tepat untuk masing-masing beban kerja beserta justifikasi teknis dan pertimbangan kepatuhannya!

**Jawaban:**

| Beban Kerja | Karakteristik Beban & Data | Tipe Storage Terpilih | Justifikasi Teknis & Kepatuhan |
|---|---|---|---|
| **Database Transaksi RME (S1)** | Relasional 6,8 TB, tumbuh 1,9 TB/tahun, 14 kueri per pembukaan rekam medis (**E3**), menuntut konsistensi ACID ketat dan replikasi asinkron antar data center (**E2**). | **Block Storage (AWS EBS gp3 / Dedicated SAN LUN)** | Basis data relasional membutuhkan latensi I/O sub-milidetik dengan throughput konsisten yang hanya dapat dipenuhi oleh block volume mentah. Dengan block storage mandiri, I/O database tidak terhambat oleh overhead protokol jaringan file-sharing. Volume dipisahkan dari komputasi agar dapat di-snapshot dan dipasang ulang secara instan saat server crash. |
| **Dokumen Bersama & SOP (S2)** | SOP klinis, formulir persetujuan medis, dan kontrak 14 asuransi mitra (±9 TB) yang diakses bersama oleh staf di 70 klinik secara read-only (**S2**). | **File Storage (AWS EFS / Managed NFS/SMB)** | Kebutuhan *concurrent multi-attach* (POSIX/SMB file-sharing) dari puluhan instansi dan workstation klinik secara simultan. File storage menyediakan sistem hierarki folder bersama dengan mekanisme locking berkas, sehingga dokter dan staf administrasi dapat membaca SOP terkini tanpa perlu menduplikasi berkas di setiap klinik. |
| **Unggahan Medis (Hasil Lab PDF & Foto Klinis) (S4)** | ±150 TB, tumbuh 4 TB/bulan, sifat data *write-once-read-many* (WORM), tidak pernah diubah setelah ditandatangani dokter, dan **dilarang keras tertimpa**. | **Object Storage (AWS S3 / Kompatibel S3)** | Volume data yang masif (ratusan terabyte) sangat mahal dan tidak efisien jika ditampung pada block storage. Object storage menyediakan skalabilitas horizontal tanpa batas, durabilitas 99,999999999% (11 9s), metadata kustom (ID Pasien, Nomor Pemeriksaan), dan fitur *Object Versioning* serta *Object Lock* untuk menjamin bahwa berkas bukti klinis tidak dapat dimanipulasi atau tertimpa (**S4**, **A2**). |

---

## Pertanyaan 2 — Mitigasi Insiden Log Penuh (P5 & S6) dan Desain Kapasitas Volume

**Pertanyaan:**
Insiden **P5** mengakibatkan sistem RME mati selama 190 menit karena volume log transaksi penuh tanpa peringatan (**S6**). Bagaimana arsitektur penyimpanan yang dirancang pada Modul 04 mencegah terulangnya insiden tersebut secara tuntas?

**Jawaban:**

1. **Akar Masalah Insiden P5:**
   Pada arsitektur monolitik lama KSL, sistem operasi Linux, mesin PostgreSQL, berkas data tabel (`data directory`), dan log transaksi (*Write-Ahead Logging* / WAL) berada dalam satu partisi disk fisik lokal yang sama di server Bandar Lampung. Ketika beban transaksi memuncak (Senin pagi) atau proses replikasi ke Metro mengalami *lag* (**S1**), akumulasi berkas WAL memenuhi seluruh ruang disk hingga 100%, menyebabkan kernel Linux mengunci sistem file menjadi *read-only* dan PostgreSQL langsung *crash*.
2. **Solusi Arsitektur Modul 04:**
   - **Pemisahan Partisi dan Mount Point Terpisah**:
     Sistem operasi server ditempatkan pada root volume terpisah (8 GB gp3), sedangkan data transaksi PostgreSQL dan WAL ditempatkan pada volume EBS data independen bertag `peran=data` (**K-04-002**). Jika volume log membengkak, sistem operasi server tidak akan mengalami *kernel panic* dan tetap dapat diakses untuk mitigasi.
   - **Pencegahan Penghapusan Data (`delete_on_termination = false`)**:
     Volume data tidak diikat ke masa hidup server. Jika server mengalami kerusakan fatal, server dapat dihancurkan dan diganti dengan instance baru tanpa kehilangan data transaksi sedikit pun (**volume_selamat**).
   - **Monitoring Ambang Batas 80% dan Elastic Volumes**:
     Sesuai dengan Evidence **O4**, metrik utilisasi volume dipantau secara real-time dengan ambang batas peringatan pada 80%. Berkat fitur *AWS EBS Elastic Volumes*, tim platform dapat meningkatkan ukuran volume secara dinamis via kode atau API tanpa menghentikan database (*zero-downtime volume resizing*), menghilangkan prosedur manual ad-hoc berbahaya yang terjadi saat insiden **O5**.

---

## Pertanyaan 3 — Perlindungan Integritas Data Medis, Versioning, dan Kepatuhan Regulasi

**Pertanyaan:**
Jelaskan peran *Object Versioning* dan *Lifecycle Rules* pada bucket arsip (`koma-123450022-m04-arsip-088146583391`) dalam mencegah insiden kebocoran/kehilangan data seperti **H6**, serta bagaimana desain ini mematuhi UU Pelindungan Data Pribadi (UU PDP No. 27/2022) dan retensi rekam medis 25 tahun (**A2**)!

**Jawaban:**

1. **Mencegah Kesalahan Manusia (Human Error Mitigation - H6):**
   Pada masa lalu (**H6**), seorang engineer pernah salah mengubah konfigurasi lifecycle bucket arsip uji dari konsol grafis AWS sehingga arsip selama 9 hari terhapus permanen. Pada Modul 04:
   - Seluruh aturan lifecycle dikodekan secara deklaratif di OpenTofu (`aws_s3_bucket_lifecycle_configuration`). Setiap perubahan wajib melalui *code review* dan dilarang diubah lewat konsol manual.
   - S3 Versioning memastikan bahwa perintah penghapusan tidak langsung memusnahkan data, melainkan hanya menambahkan penanda hapus (*delete marker*). Berkas asli tetap tersimpan pada versi sebelumnya (*noncurrent version*) dan dapat dipulihkan seketika.
2. **Kepatuhan terhadap UU PDP dan Regulasi Rekam Medis (A2 & S4):**
   - **Pasal 35 UU No. 27/2022 (UU PDP)** mewajibkan Pengendali Data Pribadi menjaga integritas dan keaslian data pribadi spesifik (data kesehatan). Fitur *versioning* memastikan hasil pemeriksaan laboratorium dan foto rontgen tidak dapat dipalsukan atau tertimpa oleh pihak manapun.
   - **Retensi 25 Tahun (Permenkes 24/2022 & Parameter Kasus A2)**:
     Menyimpan ratusan terabyte data pada storage standar selama 25 tahun akan membebani anggaran KSL (**G3**). Dengan menerapkan *Lifecycle Rules*:
     * Hari ke-1 s.d. 30: Disimpan di S3 Standard untuk akses cepat dokter triase dan RME (**E5**).
     * Hari ke-31 s.d. 90: Ditransisikan secara otomatis ke S3 Standard-Infrequent Access (Standard-IA).
     * Hari ke-91 ke atas: Ditransisikan ke S3 Glacier Flexible / Deep Archive dengan enkripsi AES256 terkelola.
     Strategi ini memangkas biaya penyimpanan hingga lebih dari 70% sambil tetap memenuhi klausul audit hukum dan kepatuhan retensi 25 tahun.

---

## Pertanyaan 4 — Tata Kelola State Infrastruktur (State Governance & Confidentiality)

**Pertanyaan:**
Mengapa berkas state OpenTofu/Terraform (`m04/data.tfstate`) dikategorikan sebagai aset data Rahasia (**A1**), dan bagaimana skema tata kelola aksesnya diimplementasikan untuk mencegah insiden keamanan seperti **A3** dan **A6**?

**Jawaban:**

1. **Tingkat Sensitivitas Berkas State:**
   Berkas `terraform.tfstate` adalah cetak biru digital lengkap dari seluruh infrastruktur cloud. Berkas ini memuat:
   - Alamat IP privat seluruh server database dan backend.
   - Topologi VPC, subnet, dan ID Security Group.
   - Konfigurasi enkripsi dan referensi kunci KMS.
   - Nilai variabel sensitif yang mungkin terinjeksi selama proses deployment.
   Jika berkas state jatuh ke pihak luar atau penyerang internal (*insider threat*, **A3**), penyerang memiliki peta sempurna untuk melancarkan serangan lateral (*lateral movement*) langsung ke database rekam medis.
2. **Skema Tata Kelola dan Perlindungan State:**
   - **Enkripsi Sisi Server (SSE-S3 / AWS KMS)**: State disimpan dalam bentuk terenkripsi penuh saat diam di bucket `koma-123450022-tfstate-088146583391`.
   - **Blokir Akses Publik Mutlak**: Bucket menerapkan *S3 Public Access Block* penuh.
   - **Hak Akses Minimum (Least Privilege & RBAC)**: Hanya pipeline CI/CD resmi dan akun tim platform yang memiliki hak akses. Dokter, staf klinik, maupun akun vendor pihak ketiga (**A4**, **A6**) dilarang memiliki izin IAM ke bucket state.
   - **State Locking**: Mencegah tabrakan pembaruan konfigurasi yang dapat merusak integritas sistem saat beberapa engineer bekerja secara simultan.
