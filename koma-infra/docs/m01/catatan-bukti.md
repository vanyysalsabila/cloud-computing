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
| A.1 Konsol | | (konsol EC2) | |
| A.2 CLI dua kali | | `aws ec2 run-instances …` | |
| A.3 Cek + bongkar | | `koma cek m01`, `aws ec2 terminate-instances …` | |
| B.1 Anggaran | | `tofu apply m00.tfplan` | |
| B.4 Apply pertama | | `tofu apply m01.tfplan` | |
| B.5 Potret 2 | | `koma cek m01` | |
| C.1 Plan kedua | | `tofu plan -detailed-exitcode` | |
| C.3 Refaktor | | `tofu apply m01.tfplan` | |
| C.4 Potret 3 | | `koma cek m01` | |
| D.1 Destroy + apply | | `tofu destroy`, `tofu apply` | |
| D.1 Potret 4 | | `koma cek m01` | |
| Latihan L.4 (potret 5) | | `tofu apply`, `koma cek m01` | |
| E.1 Destroy + potret 6 | | `tofu destroy`, `koma cek m01`, `koma sisa` | |
| Tugas: katalog kasus | | `tofu apply`, `koma cek m01` | |
| Tugas: destroy akhir | | `tofu destroy`, `koma cek m01` | |

## Catatan Bagian A

- Waktu konsol (klik pertama sampai `Running`): … menit … detik; jumlah isian yang disentuh: …
- Waktu CLI (Enter sampai `running`): … detik
- ID instance: `coba-konsol` …; dua `coba-cli` … dan …
- Keputusan yang tidak tercatat di mana pun selain ingatan dan riwayat terminal saya:
  - AMI yang dipilih di konsol tidak tercatat karena tidak ada tfvars atau kode
  - Ukuran instance yang dipakai saat `run-instances` CLI tidak masuk ke repo mana pun
  - Tag tambahan atau tidak — bergantung pada ingatan operator
- Semua instance Bagian A sudah di-terminate (bukti: `describe-instances` kosong; `tanpa_instance_liar` lulus pada potret …): ya / belum

## Catatan Bagian D

- Plan kedua (C.1): exit code = 
- ID sebelum destroy: `web` …, `api` …
- ID sesudah apply ulang: `web` …, `api` …
- Waktu destroy: … ; waktu apply ulang: …
- Potret yang meluluskan `reproducible`: potret … dan potret …

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

- Katalog kasus (`default` di `variables.tf`): kunci … peran … ukuran …
- Potret aktif katalog kasus: nomor …, waktu …
- Potret bersih terakhir: nomor …, waktu …; `tugas_lulus`: …
