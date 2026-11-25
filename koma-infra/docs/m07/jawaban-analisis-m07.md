# Jawaban Analisis — Modul 07 (draf)

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada **Tugas Individu — Modul 07** di Workbench. Bukti berasal dari pekerjaan Anda (`docs/m07/catatan-bukti.md`, `latihan-m07.md`, tautan run, bukti verifier) dan berkas kasus kelompok. Sebut kode bukti kasus (G1–G6, A1, H1–H6, O1) saat memakai faktanya, dan rujuk baris `K-07-*` bila relevan. Angka Sumatera Data di naskah adalah contoh, bukan angka kasus Anda.

## Pertanyaan 1 — CMP sebagai kode

| Fungsi CMP ([S] hlm. 270–274) | Sudah sebagai kode di modul ini (berkas) | Masih butuh platform |
|---|---|---|
| | | |

Bagian stack saya yang paling sulit dipindah ke penyedia lain, dengan G5 dan G6 kasus saya:

Apakah lapisan abstraksi lintas penyedia sepadan dengan biayanya ([S] hlm. 292–296; Morris hlm. 40–41, 60):

## Pertanyaan 2 — Satu kode, dua lingkungan, dan biaya yang bertuan

Bukti kode sama dan state terpisah (key state, plan, tfvars):

Risiko yang dihilangkan dan yang muncul dibandingkan *multi-environment stack* (Morris hlm. 122–126):

Insiden biaya G3 kasus saya: dapatkah ditelusuri ke G1 sekarang, dan apa yang masih menghalanginya di AWS:

Lapis kontrol yang paling mudah diakali, dan bagaimana pipeline menutupnya:

## Pertanyaan 3 — Integrasi dan kegagalan

Bukti D.1 dan D.2 (waktu, jumlah percobaan):

*At-least-once*, DLQ, dan konsumen idempoten (Fehling hlm. 144–145; Brisals & Hedger hlm. 153):

Bila sistem on-premises (H1) tidak menjangkau cloud satu hari, atau fungsi gagal sepanjang malam (H3, H6):

Tantangan integrasi paling relevan ([S] hlm. 310–312) dan retensi lab dibandingkan H4:

## Pertanyaan 4 — Hanya lewat pipeline

Bukti saya (tautan run yang ditahan, pesan gerbang, tag `penerap`, `jejak_cloudtrail`):

Bagaimana pipeline mewujudkan *make changes using only the automated process* (Morris hlm. 247–249), dan insiden H6 kasus saya:

| Jalan pintas | Kontrol yang mencegah | Kontrol yang hanya mendeteksi |
|---|---|---|
| `tofu apply` lokal dengan identitas `aws login` | | |
| Role yang sama untuk pull request | | |
| Merge PR yang gagal gerbang | | |

Satu kontrol tambahan yang paling sepadan bagi kasus saya, dan biayanya:
