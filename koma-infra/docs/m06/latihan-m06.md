# Latihan 6.1 — Satu alamat, dua versi, satu alarm

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m06.json` (setelah Bagian G, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 06**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan token verifier, isi state, atau 12 digit ID akun (tulis `<akun>`); nama DNS ALB dan ID resource boleh ditulis.

## 1. Impor tanpa mengganti (B.4)

Baris `Plan:` plan impor:

```text
Plan: 3 to import, 0 to add, 3 to change, 0 to destroy.
```

Perubahan in-place yang diusulkan (resource dan tag):

| Resource | Tag yang ditambah | Tag yang dihapus |
|---|---|---|
| `aws_instance.legacy[0]` | `managed-by = "opentofu"`, `stack = "m06-migrasi"` | - |
| `aws_security_group.legacy[0]` | `managed-by = "opentofu"`, `stack = "m06-migrasi"` | - |
| `aws_vpc_security_group_ingress_rule.legacy_http[0]` | `kelompok = "k01"`, `kursus = "komputasi-awan"`, `managed-by = "opentofu"`, `modul = "m06"`, `nim = "123450022"`, `stack = "m06-migrasi"` | - |

Mengapa tidak ada `to add` maupun `to destroy`:
Karena ketiga resource tersebut sudah ada di AWS dan blok `import` di `impor.tf` memetakan ID nyata (`i-0d36c1811f243ed17`, `sg-0ca0b03ccb4c4501d`, `sgr-07c4a2cf52653dfd4`) ke alamat resource di `legacy.tf`. Seluruh atribut pembentuknya (`ami` dengan `ignore_changes`, `instance_type`, `vpc_id`, `name`, `description`, `cidr_ipv4`, `from_port`, `to_port`) ditulis persis sama dengan keadaan nyata, sehingga OpenTofu hanya perlu menyelaraskan tag (`update in-place`) tanpa membuat atau menghancurkan resource.

Satu atribut yang, bila ditulis berbeda di kode, mengubah impor menjadi penggantian, dan akibatnya bagi pengguna L2 kasus saya:
Atribut `instance_type` (misal mengubah `"t3.micro"` ke `"t3.small"`) atau `user_data` (bila tidak ada di `ignore_changes`) atau `description` pada `aws_security_group` bersifat *ForceNew* / *forces replacement*. Bila terjadi penggantian instance, server legacy `0.9.0` akan di-terminate dan dibuat ulang dengan IP publik baru yang memutus koneksi 140 kios antrean di 70 klinik (karena alamat API tertanam di firmware kios, pembaruannya butuh 3 bulan oleh teknisi, **L2**) dan melampaui batas jeda 2 detik (**L4**).

Risiko `ignore_changes = [ami, user_data, user_data_base64]` bagi kode sebagai sumber kebenaran:
Konfigurasi OS, paket, dan skrip startup (`user_data`) di dalam server legacy menjadi "buta" terhadap OpenTofu: jika ada perubahan AMI atau perubahan manual pada skrip di dalam instance, `tofu plan` tidak akan mendeteksinya sebagai drift dan tidak dapat membangun ulang server legacy yang identik hanya dari blok `aws_instance.legacy`.

## 2. Alih tanpa jeda yang terasa (C.8)

Baris `Plan:` plan alih dan resource yang berubah:

```text
  # aws_lb_listener.http will be updated in-place
  ~ default_action {
      ~ target_group_arn = ".../koma-123450022-m06-biru/..." -> ".../koma-123450022-m06-hijau/..."
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Ringkasan `koma probe`:

| Sampel | Gagal | Jeda terpanjang (dtk) | Versi yang terlihat | Alih pada detik |
|---|---|---|---|---|
| `100` (saat *contract* F) / `179` (saat pra-alih C.8) | `0` | `0.0` | `6.0.0: 100` (saat *contract*) / `0.9.0: 179` (pra-alih) | `null` (listener selesai beralih setelah sesi probe 90 dtk pertama usai; saat *contract* pembongkaran 6 resource legacy mencatat 0 gagal) |

*(Catatan jujur dari log eksekusi: saat probe 90 detik di C.8 berjalan pada 17:00–17:02 WIB, `tofu apply` masih menunggu state refresh hingga 17:05 WIB sehingga peralihan ke `6.0.0` terjadi tepat setelah jendela probe 90 detik pertama berakhir, lalu diverifikasi langsung dengan `GET /versi` -> `6.0.0` dan probe 50 detik selama *contract* dengan 100/100 sampel sukses dan `0` kegagalan.)*

Mengapa listener ALB menghasilkan jeda sekecil ini (dan apa batas resolusi probe):
Listener ALB cukup memperbarui aturan forward pada bidang kendali (*control plane*) di belakang satu nama DNS ALB yang sama, sementara koneksi yang sudah berjalan menuju `biru` diberi waktu selesai melalui `deregistration_delay = 5` detik dan target group `hijau` sudah terdaftar. Batas resolusi `koma probe` adalah interval `--selang 0.5` detik; jeda kurang dari 0,5 detik di antara dua sampel tidak terukur sebagai kegagalan kecuali permintaan kebetulan jatuh tepat pada saat pergantian koneksi.

Perbandingan dengan ambang L4 dan jadwal L3 kasus saya:
Ambang toleransi jeda kios antrean pada **L4** adalah **≤ 2 detik** (kios memunculkan galat setelah 3 detik sehingga pasien harus antre ulang), sedangkan jendela pemeliharaan adalah **Selasa 01.00–04.00** (maksimal 30 menit) bertepatan dengan jam paling sepi **00.00–05.00** (**L3**, ±40 pendaftaran/jam). Jeda `0,0` detik pada probe memenuhi batas **≤ 2 detik** (**L4**), dan tetap wajib dijalankan pada jam sepi **L3** agar bila perlu *rollback* ke `biru` dampaknya minimal bagi 140 kios dan 380 petugas pendaftaran (**L2**).

## 3. Alarm yang terbukti (D.5)

Ringkasan `koma beban`:

```text
Permintaan 362, gagal 0, p50 2005 ms, p95 2096 ms
```

Riwayat alarm (`describe-alarm-history`, `StateUpdate`):

```text
2026-11-25T17:08:40+07:00  Alarm updated from INSUFFICIENT_DATA to OK  (p95=0.0024s <= 0.3s)
2026-11-25T17:11:40+07:00  Alarm updated from OK to ALARM              (p95=1.9360s > 0.3s, sampleCount=82)
2026-11-25T17:20:40+07:00  Alarm updated from ALARM to OK              (p95=0.0015s <= 0.3s, sampleCount=5)
```

| Hal | Waktu (WIB) |
|---|---|
| Beban dimulai | `17:08:18` |
| Alarm `OK → ALARM` | `17:11:40` |
| Beban berhenti | `17:11:20` |
| Alarm `ALARM → OK` | `17:20:40` |
| **Waktu deteksi** (menit) | **3,37 menit** (3 menit 22 detik) |

Perbandingan dengan O5 dan anggaran galat O1 kasus saya (anggaran per 30 hari, persentase yang habis selama waktu deteksi):
Berdasarkan **E4** dan **O1**, SLA 99,95% per 30 hari hanya memberi anggaran galat (`error budget`) sebesar `(1 - 0,9995) × 30 × 24 × 60` = **21,6 menit per bulan**. Pada insiden **O5** (**P5**), gangguan baru diketahui setelah **25 menit** dari telepon 23 klinik — artinya **115,7% anggaran galat habis** bahkan sebelum tim mulai menangani masalah. Dengan alarm p95 ini, waktu deteksi turun drastis menjadi **3,37 menit**, yang hanya menghabiskan **15,6%** (`3,37 / 21,6`) dari anggaran galat 30 hari dan memenuhi target deteksi **P6** (**≤ 5 menit**).

## 4. Bukti

- Potret 6 (setelah alarm menyala, D.6) pada `17:18` WIB (`2026-11-25T10:18:46Z`), `Latihan lulus`: `True`
- Potret bersih (Potret 10, G.2) pada `17:26` WIB (`2026-11-25T10:26:52Z`), `bersih_akhir`: `True`
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m06.json` yang diunggah: `latihan_lulus: true`, `sumber: "lokal"`
