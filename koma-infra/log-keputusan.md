# Log Keputusan

Satu baris per keputusan desain. ID berbentuk `K-<modul>-<nomor>`, misalnya `K-01-001`. Alasan
merujuk kode bukti kasus kelompok (P1–P6, E1–E8, …). Keputusan kelompok yang sama boleh muncul di
repo setiap anggota; kolom Pengusul diisi NIM anggota yang mengusulkan.

| ID | Tanggal | Keputusan | Alasan (rujuk kode bukti kasus) | Pengusul (NIM) |
|---|---|---|---|---|
| K-01-001 | 2026-11-09 | Ukuran server dikelola lewat katalog `{kecil, sedang, besar}` di `variables.tf`, bukan mengetik `instance_type` EC2 langsung | Mencegah instance berukuran tidak standar yang tidak terpantau (P5); memudahkan audit dan review PR | 123450022 |
| K-01-002 | 2026-11-09 | Refaktor dari `aws_instance.web` tunggal ke `aws_instance.layanan[*]` menggunakan blok `moved` | Server yang melayani API RME tidak boleh di-replace tanpa rencana (E4 SLA 99,95%); `moved` memastikan refaktor nama tidak memicu destroy | 123450022 |
| K-01-003 | 2026-11-09 | IMDSv2 (`http_tokens = "required"`) diwajibkan pada semua instance | Mencegah akses metadata instance dari proses yang tidak berwenang; best practice AWS Security untuk data kesehatan (A3) | 123450022 |
| K-02-001 | 2026-11-10 | Menerapkan pola AMI Baking (waktu siap 32 detik) dibanding server goreng (225 detik) untuk server API | Jaringan 70 klinik dan 2 laboratorium bergantung pada VPN broadband 20-50 Mbps yang tidak stabil (E2, C3); AMI mandiri memangkas waktu boot hingga 85% untuk memenuhi target rebuild ≤ 4 jam (P6) | 123450022 |
| K-02-002 | 2026-11-10 | Menetapkan prinsip *Immutable Server* dengan jeda layanan rilis 75 detik (5,78% error budget bulanan 21,6 menit) | Menghilangkan modifikasi manual dan konfigurasi drift pada server RME; mencegah terulangnya insiden P5 (server manual yang tidak terdokumentasi) serta mematuhi SLA 99,95% (E4, O1) | 123450022 |
| K-02-003 | 2026-11-10 | Memilih ukuran server API `t3.micro` dan membatasi Security Group port 80 hanya untuk prefix /32 IP pengembang (`103.59.45.34/32`) | Menjaga efisiensi biaya dan keamanan sandbox agar tidak terpapar publik (0.0.0.0/0) sesuai kebijakan data medis KSL berlabel Rahasia (A1, A3, A6, G3) | 123450022 |
| K-03-001 | 2026-11-14 | Segmentasi Multi-Tier VPC (10.1.0.0/16) memisahkan Tier Publik (ALB) dan Tier Privat (Web/API & Database) di 2 AZ | Menggantikan segmen flat /24 yang rentan pergerakan lateral ransomware (E7, A3); mengisolasi data medis rahasia pasien (A1, A2) | 123450022 |
| K-03-002 | 2026-11-14 | Menerapkan arsitektur tanpa NAT Gateway pada subnet privat dan mengandalkan routing internal lokal | Menghilangkan biaya mahal NAT Gateway (~$32/bln) yang memboroskan anggaran (G3); mencegah eksfiltrasi data rekam medis ke internet secara absolut (A2, A3) | 123450022 |
| K-03-003 | 2026-11-14 | Memisahkan siklus hidup infrastruktur jaringan (`m03-network`) dari siklus hidup aplikasi (`m03-app`) dengan matriks SG berantai | Memastikan VPC dan subnet stabil tidak terganggu saat service web/API dan ALB diperbarui atau di-deploy ulang (E4 SLA 99,95%, E3) | 123450022 |
| K-04-001 | 2026-11-14 | Mengelola state OpenTofu di backend remote S3 terenkripsi AES256 dengan versioning dan blokir publik total | Menjamin integritas state tim 14 orang tanpa risiko konkurensi (E6); melindungi blueprint infrastruktur rahasia dari ancaman kebocoran (A1, A3) | 123450022 |
| K-04-002 | 2026-11-14 | Memisahkan siklus hidup volume EBS data (`peran=data`, `delete_on_termination=false`) dari server database | Menjamin persistensi data transaksi medis 6,8 TB saat server di-replace atau di-upgrade (S1, P5, S6, volume_selamat) | 123450022 |
| K-04-003 | 2026-11-14 | Menerapkan Object Versioning dan dua aturan lifecycle terkelola kode pada bucket arsip medis | Menjamin hasil lab 150 TB tidak tertimpa (S4); mencegah insiden kehilangan arsip manual (H6); mematuhi retensi rekam medis 25 tahun (A2) secara hemat biaya (G3) | 123450022 |
