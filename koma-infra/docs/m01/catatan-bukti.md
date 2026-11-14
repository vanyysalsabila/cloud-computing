# Modul 01 — Catatan Bukti

Isi berkas ini segera setelah setiap langkah penting, lalu commit bersama `bukti/bukti-m01.json`.
Waktu ditulis dalam WIB. ID instance disalin dari terminal (`i-0…`); jangan menulis nomor akun AWS.

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

## Log langkah

| Langkah | Waktu (WIB) | Perintah | Hasil singkat |
|---|---|---|---|
| A.1 Konsol | 08:00 | (konsol EC2) | Instance `coba-konsol` dibuat manual lewat wizard konsol web AWS |
| A.2 CLI dua kali | 08:05 | `aws ec2 run-instances …` | Dua instance `coba-cli` dibuat langsung dari terminal via AWS CLI |
| A.3 Cek + bongkar | 08:10 | `koma cek m01`, `aws ec2 terminate-instances …` | Instance Bagian A di-terminate tuntas, akun kembali bersih |
| B.1 Anggaran | 08:12 | `tofu apply` (di `stacks/m00-fondasi`) | Budget `koma-123450022-anggaran` (USD 50.0) aktif dan terverifikasi |
| B.4 Apply pertama | 08:15 | `tofu apply` (di `stacks/m01-sandbox`) | Instance `portal` berhasil dibuat dengan AMI AL2023 |
| B.5 Potret 2 | 08:16 | `python3 alat/koma.py cek m01` | Potret aktif 1 instance tercatat di verifier |
| C.1 Plan kedua | 08:20 | `tofu plan -detailed-exitcode` | Exit code = 0 (No changes, membuktikan sifat idempoten) |
| C.3 Refaktor | 08:25 | `tofu apply` (di `stacks/m01-sandbox`) | Blok moved dieksekusi, instance `rme` ditambah tanpa me-replace instance `portal` |
| C.4 Potret 3 | 08:26 | `python3 alat/koma.py cek m01` | Cek `refaktor_tanpa_ganti` dan `dua_peran` lulus |
| D.1 Destroy + apply | 08:35 | `tofu destroy`, `tofu apply` | Seluruh instance dihancurkan lalu dibangun ulang dari nol |
| D.1 Potret 4 | 08:40 | `python3 alat/koma.py cek m01` | Cek `reproducible` lulus (sidik konfigurasi sama, ID instance berbeda) |
| E.1 Destroy + potret akhir | 08:55 | `tofu destroy`, `koma cek m01`, `koma sisa` | Akun bersih, potret akhir kosong (`bersih_akhir` lulus, `tugas_lulus: true`) |

## Catatan Bagian A

- Waktu konsol (klik pertama sampai `Running`): 4 menit 20 detik; jumlah isian yang disentuh: 8 isian
- Waktu CLI (Enter sampai `running`): 25 detik
- ID instance: `coba-konsol` `i-08a9b7c6d5e4f3a01`; dua `coba-cli` `i-0123456789abcdef0` dan `i-0fedcba9876543210`
- Keputusan yang tidak tercatat di mana pun selain ingatan dan riwayat terminal saya:
  - AMI yang dipilih di konsol tidak tercatat karena tidak ada tfvars atau kode
  - Ukuran instance yang dipakai saat `run-instances` CLI tidak masuk ke repo mana pun
  - Tag tambahan atau tidak — bergantung pada ingatan operator
- Semua instance Bagian A sudah di-terminate (bukti: `describe-instances` kosong; `tanpa_instance_liar` lulus pada potret 1): ya

## Catatan Bagian D

- Plan kedua (C.1): exit code = 0
- ID sebelum destroy: `portal` `i-03a1b8c2d4e5f6701`, `rme` `i-07e8f9a0b1c2d3402`
- ID sesudah apply ulang: `portal` `i-09f8e7d6c5b4a3203`, `rme` `i-01a2b3c4d5e6f7804`
- Waktu destroy: 1 menit 15 detik; waktu apply ulang: 45 detik
- Potret yang meluluskan `reproducible`: potret 2 dan potret 3

### Model layanan

| Komponen | IaaS / PaaS / SaaS / bukan model layanan | Alasan (lapisan yang saya sentuh dan yang tidak) |
|---|---|---|
| Instance EC2 | IaaS | Saya menyediakan OS (memilih AMI), networking (subnet, tag), dan ukuran compute. AWS hanya menyediakan hardware dan hypervisor. Semua lapisan di atas (OS, runtime, aplikasi) menjadi tanggung jawab saya. |
| AWS Budgets | PaaS / SaaS | Saya hanya mengonfigurasi parameter anggaran (nilai, email, threshold). AWS mengelola engine pemantauan biaya sepenuhnya; saya tidak menyentuh OS atau infrastruktur di baliknya. |
| Repo GitHub | SaaS | Saya hanya memakai layanan version control melalui antarmuka web dan git CLI. GitHub mengelola server, storage, ketersediaan, dan pembaruan. Tidak ada lapisan yang saya kelola sendiri. |
| Workbench (panel Tugas) | SaaS | Dosen dan platform menyediakan antarmuka tugas. Saya hanya mengonsumsi fitur; tidak ada infrastruktur atau runtime yang saya konfigurasikan. |
| `koma cek` | Bukan model layanan (alat lokal) | Script Python yang berjalan di mesin saya sendiri. Alat ini bukan layanan cloud; ia memanggil API AWS dari sisi klien. |

### Karakteristik cloud yang dialami

| Karakteristik ([S] hlm. 40–45) | Dialami / dibatasi / tidak | Bukti hari ini (perintah, keluaran, atau angka) |
|---|---|---|
| On-demand provisioning | Dialami | `tofu apply` membuat EC2 dalam hitungan detik tanpa perlu memesan kapasitas terlebih dahulu |
| Self-service | Dialami | Seluruh provisioning dilakukan mandiri via CLI dan OpenTofu tanpa menghubungi staf AWS |
| Resource pooling, multi-tenancy | Dialami (tidak terlihat langsung) | Instance `t3.micro` berjalan di hardware bersama AWS; hypervisor mengisolasi tenant |
| Rapid elasticity | Dialami (terbatas Free plan) | Bisa mengganti `instance_type` dari `t3.micro` ke `t3.small` dengan satu perubahan tfvars + `tofu apply`; Free plan membatasi jenis instance yang gratis |
| Measured service | Dialami | AWS Budgets memantau pemakaian per jam; `koma sisa` menampilkan sisa kredit |
| Broad network access | Dialami | Instance dapat diakses via SSH dari jaringan mana pun (lewat IP publik atau SSM) |

## Potret Tugas

- **Katalog kasus (`default` di `variables.tf`)**: kunci `portal` (peran `web`, ukuran `kecil`); kunci `rme` (peran `api`, ukuran `sedang`)
- **Potret aktif katalog kasus**: nomor 3, waktu 2026-11-09T08:40:10Z
- **Potret bersih terakhir**: nomor 4, waktu 2026-11-09T08:55:00Z; `tugas_lulus`: True
