# Modul 05 — Laporan Audit Keamanan

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |
| Peninjau PR `m05` (NIM) | |
| Tautan *pull request* | |

Isi berkas ini sambil mengerjakan prosedur. Jangan menulis password, passphrase state, token verifier, isi state atau plan JSON, atau 12 digit ID akun AWS; tulis nama bucket sebagai `koma-<nim>-m05-laporan-<akun>`. Berkas ini ikut di-commit dan masuk `koma-module-05.zip`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| `tofu apply` stack `m00-pagar` (ringkasan baris terakhir) | |
| `aws s3control get-public-access-block` (keempat pengaturan) | |
| `tofu apply` stack `m00-verifier` setelah `izin-m05.tf` (ringkasan) | |
| Impor yang diperlukan (bila ada) | |
| Sidik jari passphrase state (8 karakter awal SHA-256, bukan passphrase-nya) | |
| Tempat Anda menyimpan salinan passphrase (jenis, bukan isinya) | |
| Komputer yang dipakai sesi ini (PC lab nomor / laptop) | |
| `conftest --version`, `trivy --version` | |

## Tabel Audit

Satu baris per temuan stack `m05-rawan` (ada enam). Nomor baris merujuk berkas di `stacks/m05-rawan/`.

| # | Temuan (berkas:baris) | Kebutuhan dilanggar | Ancaman ([S] §6.4, hlm.) | Perbaikan di `m05-aman` |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |

## Hasil Trivy

Perintah yang dijalankan dan versinya:

Satu baris per ID temuan. Untuk `m05-aman`, tulis temuan yang diterima lewat `trivy:ignore` beserta alasannya.

| Stack | ID temuan | Severity | Sesuai temuan Tabel Audit no. (atau "tambahan") | Relevan? Alasan |
|---|---|---|---|---|
| `m05-rawan` | | | | |
| `m05-rawan` | | | | |
| `m05-aman` | | | | |

Temuan Tabel Audit yang **tidak** dilaporkan Trivy:

## Hasil Conftest

| Plan | Jumlah kegagalan | Alamat yang ditolak |
|---|---|---|
| `rawan.plan.json` | | |
| `aman.plan.json` | | |

Resource yang tercatat *known after apply* pada plan aman dan karena itu tidak terperiksa kebijakan:

## Threat Model

| Butir | Isi untuk API laporan pada kasus kelompok Anda (sebut kode bukti A1–A6) |
|---|---|
| Aset | |
| Aktor ancaman | |
| Jalur serangan | |
| Kontrol yang sudah ada | |
| Risiko sisa | |

## Langkah dan bukti

Satu baris per `koma cek m05`. Potret aktif terakhir sebelum destroy harus lulus semua cek kecuali `bersih_akhir`, dan potret terakhir sebelum mengumpulkan harus potret bersih.

| Potret | Langkah | Keadaan | Waktu (WIB) | Hasil penting (`Latihan lulus` / `Tugas lulus`, cek yang gagal, versi parameter) |
|---|---|---|---|---|
| 1 | D.6 | stack aman berjalan | | |
| 2 | E.2 | kosong | | |
| 3 | Tugas Langkah 2 | dibangun ulang | | |
| 4 | Tugas Langkah 3 | setelah rotasi dan reboot | | |
| 5 | Tugas Langkah 5 | kosong | | |

Bukti tidak langsung yang hanya dapat diambil selama stack hidup:

| Bukti | Potret 1 | Potret 4 |
|---|---|---|
| Baris `KOMA-PENANDA` | | |
| Kunci tingkat atas `m05/aman.tfstate` | | |
| `describe-parameters` (tipe, versi) | | |
| `get-bucket-policy-status` | | |
| `curl` anonim ke objek laporan | | |
