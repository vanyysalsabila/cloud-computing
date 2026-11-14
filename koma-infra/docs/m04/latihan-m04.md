# Latihan Individu — Modul 04: Storage dan State sebagai Kode

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |
| Tanggal | 14 November 2026 |

---

## Latihan 1 — Arsitektur Remote State dan State Governance

### 1. Mengapa State Harus Disimpan Secara Remote (S3 Backend)
Dalam pengembangan infrastruktur sebagai kode berbasis tim di Klinik Sehat Lampung (Divisi TI 14 orang, **E6**), menyimpan berkas `terraform.tfstate` di mesin lokal memiliki risiko fatal:
1. **Risiko Konkurensi & State Corruption**: Jika dua engineer menjalankan perintah `tofu apply` secara bersamaan tanpa mekanisme *state locking* terpusat, status infrastruktur di AWS akan tertimpa secara sepihak dan memicu kegagalan integritas (*split-brain/state corruption*).
2. **Keamanan Data Rahasia**: Berkas state memuat metadata sensitif seluruh infrastruktur dalam bentuk teks terbuka (misal IP privat, ID volume, konfigurasi enkripsi). Menyimpan state di laptop pengembang melanggar regulasi privasi data medis (**A1**, **A2**).
3. **Audit dan Versioning**: Dengan menyimpan state di S3 bucket berversi (`koma-123450022-tfstate-088146583391`), setiap perubahan infrastruktur terekam riwayat versinya, memungkinkan *roll-back* konfigurasi dan audit perubahan oleh Komite Rekam Medis.

### 2. Konfigurasi Keamanan Bucket State
Bucket remote state wajib memenuhi standar keamanan tertinggi:
- **Versioning Enabled**: Mempertahankan seluruh riwayat perubahan state (`state_berversi >= 2`).
- **Server-Side Encryption (AES256)**: Seluruh metadata dan konten state dienkripsi saat diam (*at-rest*).
- **Public Access Block**: Menutup 100% akses publik (*BlockPublicAcls*, *IgnorePublicAcls*, *BlockPublicPolicy*, *RestrictPublicBuckets*).
- **Least Privilege Access**: Hanya prinsipal IAM tim platform resmi yang memiliki izin membaca dan menulis ke prefix `m04/data.tfstate`.

---

## Latihan 2 — Pemisahan Siklus Hidup Komputasi dan Penyimpanan (EBS Data Persistence)

### 1. Prinsip Decoupling Compute dan Storage
Pada arsitektur monolitik tradisional KSL (**P5**, **S6**), sistem operasi server database dan data transaksi RME berada dalam satu disk lokal server fisik. Ketika volume penuh atau server mengalami crash, seluruh layanan berhenti selama 190 menit (**P5**).

Pada Modul 04, tim platform menerapkan pemisahan mutlak (*decoupling*):
- **Server DB (`aws_instance.db`)**: Beroperasi secara stateless / immutable di subnet privat, bertindak hanya sebagai unit komputasi (PostgreSQL / RME engine).
- **Volume Data (`aws_ebs_volume.data`)**: Didefinisikan sebagai sumber daya independen bertag `peran=data`, terenkripsi (`encrypted=true`), dengan tipe `gp3`.
- **Attachment (`aws_volume_attachment.db_data`)**: Mengaitkan volume ke instance dengan parameter krusial `stop_instance_before_detaching = true` dan tanpa flag `delete_on_termination`.

### 2. Pembuktian Volume Selamat (`volume_selamat`)
Ketika server `db` dihancurkan atau diganti karena patching kernel/pergantian versi (`tofu apply -replace="aws_instance.db"`):
1. Instance lama di-terminate.
2. Volume EBS data tetap utuh (*preserved*), data transaksi medis 6,8 TB (**S1**) tidak hilang sedetik pun.
3. Instance baru diluncurkan dan OpenTofu secara otomatis memasang kembali volume data yang sama ke instance baru tersebut.
4. Verifier membuktikan bahwa `ID volume lama == ID volume baru` dan `ID instance lama != ID instance baru`.

---

## Latihan 3 — Object Storage dan Lifecycle Policies untuk Arsip Medis

### 1. Kebutuhan Storage KSL (Evidence Pack S1–S8 & H4)
- **S4 (Unggahan Medis)**: Hasil lab PDF, foto klinis, dan surat rujukan pindai mencapai ±150 TB dan tumbuh 4 TB per bulan. Data ini tidak pernah diubah setelah ditandatangani dokter dan **tidak boleh tertimpa**.
- **A2 (Regulasi PDP & Rekam Medis)**: Rekam medis wajib disimpan selama 25 tahun sejak kunjungan terakhir pasien.
- **H4 & H6 (Insiden Lifecycle)**: Di masa lalu, seorang engineer pernah salah mengubah lifecycle bucket dari konsol AWS sehingga 9 hari arsip hilang. Karena itu, seluruh aturan retensi wajib dikunci sebagai kode (IaC).

### 2. Spesifikasi Bucket Arsip (`koma-123450022-m04-arsip-088146583391`)
1. **S3 Object Versioning**: Mencegah penghapusan permanen atau penimpaan file hasil lab secara sengaja maupun tidak sengaja.
2. **Server-Side Encryption**: Menggunakan enkripsi AWS SSE-S3 (AES256).
3. **Public Access Block**: Menolak segala bentuk pembacaan langsung dari internet.
4. **Dua Aturan Lifecycle Terkelola Kode**:
   - **Aturan 1 (Transisi & Retensi Noncurrent Version)**: Objek versi lama yang tertimpa secara otomatis dialihkan ke kelas penyimpanan hemat biaya (misal GLACIER / STANDARD_IA) setelah 30 hari, dan dihapus permanen hanya setelah periode retensi selesai (memenuhi syarat `any(x["versi_lama"] for x in lc)`).
   - **Aturan 2 (Transisi Arsip Laporan)**: Laporan ringkasan harian di prefix `laporan/` ditransisikan ke kelas Glacier setelah 90 hari untuk efisiensi biaya.

---

## Latihan 4 — Prosedur Eksekusi dan Verifikasi di Lab

### 1. Urutan Penerapan Stack
```bash
# 1. Pindah ke direktori koma-infra
cd ~/workbench-workspace/cloud-computing/koma-infra

# 2. Inisialisasi dan bangun stack state backend (m00-state)
cd stacks/m00-state
tofu init
tofu apply -auto-approve

# 3. Inisialisasi dan bangun stack data (m04-data)
cd ../m04-data
tofu init
tofu apply -auto-approve

# 4. Unggah objek laporan untuk menghasilkan versi ganda (arsip_berversi >= 2)
aws s3 cp laporan-v1.json s3://koma-123450022-m04-arsip-088146583391/laporan/ringkasan-harian.json
aws s3 cp laporan-v2.json s3://koma-123450022-m04-arsip-088146583391/laporan/ringkasan-harian.json

# 5. Picu pembaruan state kedua kali untuk menghasilkan state_berversi >= 2
tofu apply -auto-approve

# 6. Ambil Potret 1 (Pemeriksaan kriteria latihan)
python3 ../../alat/koma.py cek m04 --lokal

# 7. Uji Immutability & Bukti Volume Selamat (Ganti instance db)
tofu apply -replace="aws_instance.db" -auto-approve

# 8. Ambil Potret 2 (Verifikasi volume_selamat)
python3 ../../alat/koma.py cek m04 --lokal

# 9. Pembersihan Sesi (Hancurkan stack m04-data, pertahankan bucket state)
# Kosongkan objek arsip terlebih dahulu agar bucket dapat di-destroy
aws s3 rm s3://koma-123450022-m04-arsip-088146583391 --recursive
tofu destroy -auto-approve

# 10. Ambil Potret 3 (Verifikasi bersih_akhir -> 100% LULUS)
python3 ../../alat/koma.py cek m04 --lokal
```
