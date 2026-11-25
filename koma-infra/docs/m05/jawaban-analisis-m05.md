# Jawaban Analisis — Modul 05 (draf)

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada **Tugas Individu — Modul 05** di Workbench. Bukti berasal dari pekerjaan Anda (`docs/m05/laporan-audit.md`, `latihan-m05.md`, bukti verifier) dan berkas kasus kelompok. Sebut kode bukti kasus (A1–A6) saat memakai faktanya, dan rujuk baris `K-05-*` bila relevan. Jangan menuliskan nilai rahasia atau passphrase.

## Pertanyaan 1 — Klasifikasi temuan

| # | Temuan (berkas:baris) | Kebutuhan dilanggar | Ancaman ([S] §6.4, hlm.) |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |
| 6 | | | |

Temuan paling berbahaya bagi organisasi pada kasus saya, ditimbang dengan A1, A2, dan A6 (bandingkan sekurangnya dua kandidat):

## Pertanyaan 2 — Di mana rahasia berada

| Tempat | Bentuk (teks biasa / terenkripsi, dengan apa) | Siapa yang dapat membaca | Bukti saya |
|---|---|---|---|
| Dibangkitkan | | | |
| State `m05/aman.tfstate` | | | |
| Parameter Store | | | |
| Server (`/etc/koma/db.env`, proses) | | | |
| `aman.plan.json`, layar, log | | | |

Apa yang terjadi saat rotasi (versi parameter, server, reboot):

Mengapa `sensitive = true` tidak cukup, dan apa yang ditambahkan enkripsi state (Hafner, 2025, hlm. 67, 70, 173–177):

Risiko baru yang muncul (passphrase pribadi, PC lab, plan JSON) dan cara saya menanganinya:

Kaitan dengan satu rahasia pada A5 kasus saya (Morris, 2025, hlm. 155–158):

## Pertanyaan 3 — Pagar di titik mana

| Temuan | Trivy? (ID) | Conftest? (alamat) |
|---|---|---|
| | | |

Mengapa keduanya berbeda; apa yang tidak dapat diperiksa keduanya sebelum apply (`aws_iam_role_policy.dekripsi`):

Lapisan desain (Morris, 2025, hlm. 392) dan titik alur kerja (hlm. 393–394) untuk pagar akun, Trivy, Conftest, dan verifier:

Apakah pagar ini menahan terulangnya insiden A6 kasus saya (seluruhnya, sebagian, tidak), dan mengapa:

## Pertanyaan 4 — Model keamanan

Perimeter yang masih ada di akun saya dan yang menggantikannya (Surianarayanan & Chelliah, 2023, hlm. 192–193):

Yang dapat dan tidak dapat dilakukan verifier dosen (`ec2:Describe*`, 100 byte state, parameter):

Yang dapat dilakukan peninjau PR saya, dan siapa pun yang memegang sesi `aws login` yang tertinggal di PC lab (*insider threat*, hlm. 205):

Perbandingan dengan pihak ketiga pada A4 kasus saya:
