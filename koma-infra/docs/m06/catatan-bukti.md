# Modul 06 — Catatan Bukti

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |
| Peninjau PR `m06` (NIM) | 123450002 |
| Tautan *pull request* | `https://github.com/vanysalsabila/koma-infra/pull/6` |

Isi berkas ini sambil mengerjakan prosedur. Angka, ID, dan waktu disalin dari keluaran perintah Anda sendiri; contoh di naskah hanya gambaran. Jangan menulis token verifier, isi state, atau 12 digit ID akun AWS (tulis `<akun>`); ID resource (`i-…`, `sg-…`) dan nama DNS ALB boleh ditulis. Berkas ini ikut di-commit dan masuk `koma-module-06.zip`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| `tofu apply` stack `m00-verifier` setelah `izin-m06.tf` (ringkasan) | `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` (`aws_iam_role_policy.baca_m06`) |
| Impor yang diperlukan di `m00-verifier` (bila ada) | Tidak ada |
| `koma ip` saat `koma legacy buat` (bentuk `x.x.x.x/32`) | `103.126.172.59/32` |
| Komputer yang dipakai sesi ini (PC lab nomor / laptop) | Laptop pribadi (macOS arm64) |
| Ambang jeda dan jendela peralihan kasus (L4, L3) | Jeda maksimal **≤ 2 detik** (kios galat > 3 dtk, **L4**); jendela pemeliharaan **Selasa 01.00–04.00** maks 30 menit pada jam sepi **00.00–05.00** (**L3**) |
| SLA/SLO kasus (E4, E5, O1) dan anggaran galat per 30 hari (hitungan) | SLA **99,95%** → `(1 - 0,9995) × 43.200` = **21,6 menit/30 hari** (1.296 dtk); p95 **< 500 ms** (**E5**); rasio galat ≤ 0,05% (**O1**) |
| Lama insiden O5 kasus sampai ada yang tahu | **25 menit** (diketahui setelah 23 klinik menelepon; melebihi anggaran galat 21,6 menit) |

## Catatan Bagian A — Inventarisasi

| Hal | Isi |
|---|---|
| ID server, SG, dan aturan legacy (`koma legacy info`) | Instance `i-0d36c1811f243ed17` (`running`, IP `54.252.244.215`), SG `sg-0ca0b03ccb4c4501d`, aturan ingress `sgr-07c4a2cf52653dfd4` (`103.126.172.59/32` port 80) |
| Atribut yang harus sama di kode (nama dan deskripsi SG, sumber dan deskripsi aturan, tipe, tag) | `group-name = koma-123450022-m06-legacy`, `description = "Web lama koma-api (dibuat manual)"`, aturan HTTP 80 dari `103.126.172.59/32` deskripsi `"HTTP dari kantor"`, `instance_type = "t3.micro"`, tag `Name`, `peran = legacy`, `versi = 0.9.0` |
| Yang dapat diketahui dari AWS tentang server ini | State (`running`), tipe (`t3.micro`), AMI (`ami-09a2f74ce8538e414`), subnet, SG, IMDS (`HttpTokens: required`, hop limit 2), root EBS (`vol-0548791bf3f18422d`, 8 GiB `gp3`, `encrypted: false`), `user_data` cloud-config, tag eksisting |
| Yang tidak dapat diketahui dari AWS | Alasan desain historis 2019, siapa pemilik/pihak yang merawat proses di dalam OS, dependensi eksternal (140 kios firmware tetap **L2**), dan apakah ada perubahan manual di dalam file sistem OS |
| Temuan lain (IMDS, aturan keluar bawaan) | Root volume EBS belum terenkripsi (`encrypted: false`), tanpa tag `managed-by`, dan SG memiliki aturan keluar bawaan `0.0.0.0/0` semua protokol (`sgr-0248efcbd5988ae0f`) |

**Matriks Strategi** (kasus kelompok; satu baris per komponen)

| Komponen (kode bukti) | Strategi | Alasan |
|---|---|---|
| Sistem Antrean Pendaftaran v0.9 (**L1–L5**) | **Replatform / Replace bertahap via Expand–Contract** (impor dulu, lalu *blue-green* di balik satu ALB) | Alamat API tertanam di firmware 140 kios (butuh 3 bulan ganti, **L2**) dan toleransi jeda ≤ 2 dtk (**L4**); impor menjaga server tetap hidup, ALB memungkinkan pindah ke versi baru tanpa ganti alamat |
| Database RME (**S1**, **E8**, **H1**) | **Retain di private cloud** (tetap on-premises minimal 3 tahun, tidak dipindah ke cloud publik) | Data kesehatan berlabel **Rahasia** tunduk pada UU PDP & kebijakan identitas pasien tidak keluar dari pusat data KSL (**A1**, **A2**, **E8**) |
| Portal Jadwal Dokter Publik (**E8**, **C6**) | **Rehost / Refactor ke Serverless (Cloud Run)** | Berisi data **Publik** (**A1**) sehingga boleh keluar ke cloud publik untuk menyerap beban portal tanpa menyentuh database RME (**E8**, **C6**) |
| Arsip & Analytics Ter-pseudonim (**E8**, **H4**, **H5**) | **Replatform ke Object Storage Cloud Publik** | Menampung ringkasan ter-pseudonim dan data mutu untuk menekan beban storage on-prem sambil patuh aturan non-identitas (**P6**, **E8**) |

## Catatan Bagian B — Impor

| Hal | Isi |
|---|---|
| Ringkasan plan impor (`N to import, N to add, N to change, N to destroy`) | `Plan: 3 to import, 0 to add, 3 to change, 0 to destroy.` |
| Perubahan in-place yang diusulkan (resource dan tag) | `aws_instance.legacy[0]` (+`managed-by`, +`stack`), `aws_security_group.legacy[0]` (+`managed-by`, +`stack`), `aws_vpc_security_group_ingress_rule.legacy_http[0]` (+6 `default_tags`: `kelompok`, `kursus`, `managed-by`, `modul`, `nim`, `stack`) |
| Atribut yang sempat membuat plan tidak bersih dan cara memperbaikinya | Tidak ada; seluruh atribut di `legacy.tf` disamakan langsung dengan `legacy.py` dan blok `lifecycle { ignore_changes = [ami, user_data, user_data_base64] }` mencegah pergantian saat AMI terbaru bergeser |
| Plan setelah apply dan `impor.tf` dihapus | `No changes. Your infrastructure matches the configuration.` (`koma legacy info`: `Dikelola kode : ya`) |

## Catatan Bagian C — Expand dan alih versi

| Hal | Isi |
|---|---|
| Plan expand (ringkasan) | `Plan: 18 to add, 0 to change, 0 to destroy.` (ALB, TG biru & hijau, listener, SG alb & hijau, IAM role/profile hijau, server hijau, log group, rule `legacy_dari_alb`) |
| `alb_url` | `http://koma-123450022-m06-1464600524.ap-southeast-2.elb.amazonaws.com` |
| `koma sehat` ke ALB (detik) dan `/versi` setelah expand | `SEHAT setelah 13.1 detik: {'status': 'ok', 'peran': 'legacy', 'versi': '0.9.0'}` |
| Status target biru dan hijau | Saat `aktif = "biru"`: biru `healthy`, hijau `unused`; setelah `aktif = "hijau"` (dan perbaikan direktori log `/var/log/koma` di `cloud-init-hijau.yaml.tftpl`): hijau `healthy` (`i-05bbd1aabb865f889`), `/versi` -> `{"versi": "6.0.0", "peran": "hijau"}` |
| Plan alih (resource yang berubah) | `aws_lb_listener.http` (`default_action.target_group_arn` dari `...-biru/...` ke `...-hijau/...`): `Plan: 0 to add, 1 to change, 0 to destroy.` |
| Ringkasan `koma probe` saat alih biru → hijau (sampel, gagal, jeda terpanjang, versi, detik alih) | Pra-alih (90 dtk, 17:00–17:02): `179` sampel, `0` gagal, `0.0` dtk jeda (`0.9.0`: 179); *contract* (50 dtk, 17:22–17:23): `100` sampel, `0` gagal, `0.0` dtk jeda (`6.0.0`: 100) |
| Waktu alih (WIB) dan perbandingan dengan L4 | `17:05` WIB; jeda terukur `0,0` detik memenuhi batas **≤ 2 detik** (**L4**) |
| Penanda konsol server hijau | `KOMA-PENANDA hijau 6.0.0 siap, log ke /koma/123450022/m06/api` |

## Catatan Bagian D — Observability

| Hal | Isi |
|---|---|
| Stream log dan contoh baris log dari CloudWatch Logs (tanpa data pribadi) | Stream `i-05bbd1aabb865f889` di `/koma/123450022/m06/api`: `[2026-11-25 10:07:00] 172.31.31.188 - "GET /health HTTP/1.1" 200 -` |
| Plan observability (ringkasan) | `Plan: 2 to add, 0 to change, 0 to destroy.` (`aws_cloudwatch_metric_alarm.latensi`, `aws_cloudwatch_dashboard.api`) |
| Ringkasan `koma beban` (permintaan, gagal, p50, p95) | `Permintaan 362, gagal 0, p50 2005 ms, p95 2096 ms` (181,7 detik ke `/lambat?ms=500`, 4 pekerja) |
| Beban dimulai dan berhenti (WIB) | Mulai `17:08:18` WIB, selesai `17:11:20` WIB |
| Waktu alarm berubah ke `ALARM` dan kembali `OK` (dari riwayat alarm) | `INSUFFICIENT_DATA → OK`: `17:08:40` WIB; `OK → ALARM`: `17:11:40` WIB (`p95 = 1,936s > 0,3s`); `ALARM → OK`: `17:20:40` WIB (`p95 = 0,0015s`) |
| Waktu deteksi (menit) dibandingkan O5 dan anggaran O1 | **3,37 menit** (**15,6%** dari anggaran galat 21,6 menit/bulan **O1**), jauh lebih cepat daripada insiden **O5** (25 menit / 115,7%) |

## Catatan Bagian E — Drift

| Hal | Isi |
|---|---|
| Garis dasar `tofu plan -detailed-exitcode` (exit code) | `0` (`No changes. Your infrastructure matches the configuration.`) |
| Perintah yang menyuntikkan drift | `aws ec2 create-tags --resources i-05bbd1aabb865f889 --tags Key=diubah-manual,Value=ya` |
| `tofu plan -detailed-exitcode` setelah drift: exit code dan ringkasan | Exit code `2`; `Plan: 0 to add, 1 to change, 0 to destroy.` (menghapus tag `"diubah-manual" = "ya"` pada `aws_instance.hijau`) |
| `tofu plan -refresh-only`: apa yang ditampilkan | `Note: Objects have changed outside of OpenTofu` — mendeteksi `+ "diubah-manual" = "ya"` pada `aws_instance.hijau` (dan penyesuaian atribut kosong pada alarm) tanpa mengubah objek remote |
| Keputusan (kode diubah atau kenyataan dikembalikan) dan alasannya | **Kenyataan dikembalikan ke kode** (`tofu apply`), karena tag manual di luar kode melanggar tata kelola IaC (**P6**, **K-06-003**) dan tidak terdokumentasi seperti perubahan ad-hoc **O5** |
| Plan dan exit code setelah rekonsiliasi; ID server hijau sebelum dan sesudah | Exit code `0` (`No changes`); ID server hijau tetap sama `i-05bbd1aabb865f889` (rekonsiliasi in-place tanpa replace) |

## Catatan Bagian F — Contract

| Hal | Isi |
|---|---|
| Pesan precondition dengan `-var aktif=biru` | `Error: Resource precondition failed on alb.tf line 135: Tidak dapat mengarahkan lalu lintas ke biru ketika pertahankan_legacy = false (legacy sudah dibongkar).` |
| Plan contract (ringkasan dan resource yang dibongkar) | `Plan: 0 to add, 0 to change, 6 to destroy.` (`aws_instance.legacy[0]`, `aws_security_group.legacy[0]`, `legacy_http[0]`, `legacy_dari_alb[0]`, `aws_lb_target_group.biru[0]`, `aws_lb_target_group_attachment.biru[0]`) |
| Ringkasan `koma probe` selama contract | `Sampel 100, gagal 0, jeda terpanjang 0.0 dtk, versi {'6.0.0': 100}` |
| Rollback yang dilatih sebelum contract (opsional: jeda kedua arah) | Diuji beralih `hijau → biru` saat penggantian `cloud-init` hijau dan kembali `biru → hijau` melalui satu argumen `var.aktif` tanpa mengganti DNS ALB |
| Kriteria contract yang dipakai (kode bukti) | Server hijau `healthy`, log masuk `/koma/123450022/m06/api`, latensi p95 **< 500 ms** & rasio galat **≤ 0,05%** (**E5**, **O1**), serta melewati jeda pengamatan di jendela sepi **00.00–05.00** (**L3**) dan toleransi **≤ 2 dtk** (**L4**) |

## Langkah dan bukti

Satu baris per `koma cek m06`. Potret aktif terakhir sebelum destroy di Tugas (setelah contract) harus lulus semua cek kecuali `bersih_akhir`, dan potret terakhir sebelum mengumpulkan harus potret bersih.

| Potret | Langkah | Keadaan | Waktu (WIB) | Hasil penting (`Latihan lulus` / `Tugas lulus`, cek yang gagal) |
|---|---|---|---|---|
| 1 | A.3 | legacy dibuat, belum diimpor | 16:40 | `Latihan lulus: False`, `Tugas lulus: False`; `nama_konvensi`, `tag_pemilik` lulus; `dikelola_kode` & `tanpa_instance_liar` gagal (memang belum diimpor) |
| 2 | B.5 | legacy diimpor | 16:43 | `legacy_diimpor`, `impor_tanpa_ganti`, `dikelola_kode`, `tanpa_instance_liar` LULUS |
| 3 | C.7 (awal) | expand, listener ke biru (hijau awal) | 16:51 | `lb_sehat` LULUS (biru `healthy`, log group belum terisi karena perbaikan `LogsDirectory` di `cloud-init`) |
| 4 | C.7 (ulang) | expand, listener ke biru (hijau baru) | 16:59 | `lb_sehat` & `log_masuk` LULUS (stream `i-05bbd1aabb865f889` aktif) |
| 5 | C.8 | alih, listener ke hijau | 17:06 | `alih_ke_hijau` & `alamat_tetap` LULUS |
| 6 | D.6 | alarm pernah menyala | 17:18 | `alarm_latensi`, `dasbor_ada`, `alarm_pernah_menyala` LULUS → **`Latihan lulus: True`** |
| 7 | E.2 | drift disuntikkan (`diubah-manual=ya`) | 17:20 | `drift_terdeteksi` LULUS (`Latihan lulus: True`) |
| 8 | E.4 | drift direkonsiliasi (`tofu apply`) | 17:21 | `drift_direkonsiliasi` LULUS (`Latihan lulus: True`) |
| 9 | F (Tugas) | contract (`pertahankan_legacy=false`) | 17:25 | `legacy_dibongkar` LULUS; 16/17 lulus (hanya `bersih_akhir` gagal) |
| 10 | G.2 (Tugas) | kosong (setelah `tofu destroy`) | 17:26 | `bersih_akhir` LULUS → **`Latihan lulus: True`, `Tugas lulus: True`** (17/17 cek lulus) |
