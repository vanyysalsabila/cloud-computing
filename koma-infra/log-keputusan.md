# Log Keputusan

Satu baris per keputusan desain. ID berbentuk `K-<modul>-<nomor>`, misalnya `K-01-001`. Alasan
merujuk kode bukti kasus kelompok (P1–P6, E1–E8, …). Keputusan kelompok yang sama boleh muncul di
repo setiap anggota; kolom Pengusul diisi NIM anggota yang mengusulkan.

| ID | Tanggal | Keputusan | Alasan (rujuk kode bukti kasus) | Pengusul (NIM) |
|---|---|---|---|---|
| K-01-001 | 2026-11-09 | Ukuran server dikelola lewat katalog `{kecil, sedang}` di `variables.tf` untuk memetakan komponen E1 (portal dan rme) | Mencegah instance liar tidak terdokumentasi (P5); menjamin spesifikasi terukur untuk target p95 < 500 ms (E5) | 123450022 |
| K-01-002 | 2026-11-09 | Refaktor dari instance tunggal ke `for_each` menggunakan blok `moved` di `main.tf` tanpa replace | Server yang melayani API RME dilarang mengalami downtime tak terencana demi menjaga SLA 99,95% (E4) dan pemulihan ≤ 4 jam (P6) | 123450022 |
| K-01-003 | 2026-11-09 | Menonaktifkan IP publik (`associate_public_ip_address = false`) dan mewajibkan IMDSv2 pada seluruh server sandbox | Mengamankan data medis pasien berlabel Rahasia dari akses internet langsung (A1, A3) serta mengisolasi komponen backend E1 | 123450022 |
| K-02-001 | 2026-11-10 | Menerapkan pola AMI Baking (waktu siap 32 detik) dibanding server goreng (225 detik) untuk server API | Jaringan 70 klinik dan 2 laboratorium bergantung pada VPN broadband 20-50 Mbps yang tidak stabil (E2, C3); AMI mandiri memangkas waktu boot hingga 85% untuk memenuhi target rebuild ≤ 4 jam (P6) | 123450022 |
| K-02-002 | 2026-11-10 | Menetapkan prinsip *Immutable Server* dengan jeda layanan rilis 75 detik (5,78% error budget bulanan 21,6 menit) | Menghilangkan modifikasi manual dan konfigurasi drift pada server RME; mencegah terulangnya insiden P5 (server manual yang tidak terdokumentasi) serta mematuhi SLA 99,95% (E4, O1) | 123450022 |
| K-02-003 | 2026-11-10 | Memilih ukuran server API `t3.micro` dan membatasi Security Group port 80 hanya untuk prefix /32 IP pengembang (`103.59.45.34/32`) | Menjaga efisiensi biaya dan keamanan sandbox agar tidak terpapar publik (0.0.0.0/0) sesuai kebijakan data medis KSL berlabel Rahasia (A1, A3, A6, G3) | 123450022 |
| K-03-001 | 2026-11-14 | Rencana alamat organisasi dan VPC `10.1.0.0/16` (Bandar Lampung 10.0.0.0/20, Metro 10.0.16.0/20, 70 klinik 10.0.32.0/19) | Menggantikan segmen flat /24 eksisting di 70 klinik yang rentan pergerakan lateral ransomware (E7, A3); mengisolasi data medis rahasia 6,8 TB pasien (A1, A2, E2) | 123450022 |
| K-03-002 | 2026-11-14 | Menetapkan `jumlah_web = 2` server web/API di 2 Availability Zone berbeda di belakang ALB | Memenuhi target ketersediaan SLA 99,95% (maks downtime 21,6 menit/bln, E4) dan melayani 65% trafik east-west dengan beban puncak 420 req/s (E3, O3, P6) | 123450022 |
| K-03-003 | 2026-11-14 | Isolasi vendor kios antrean (140 kios) lewat ALB port 80 tanpa VPN langsung, dan subnet privat tanpa NAT Gateway | Mencegah kebocoran kredensial plain-text di 140 kios (A4, A5); menghemat $32/bln (G3); menutup 100% rute keluar internet bagi tier database (A1, A2, E7) | 123450022 |
| K-04-001 | 2026-11-14 | Menetapkan `ukuran_data_gib = 4` (batas praktikum mewakili 6,8 TB data transaksi dan ruang tumbuh 1,9 TB/thn) | Mencegah insiden disk penuh 100% yang mematikan RME selama 190 menit (P5, S6); menjaga utilisasi awal ~70% (S1, O4) | 123450022 |
| K-04-002 | 2026-11-14 | Menetapkan `retensi_versi_hari = 90` hari pada bucket S3 arsip dan transisi IA pada hari ke-30 | Melindungi 150 TB hasil lab dari penimpaan/hapus (S4, H6); menghemat >70% biaya penyimpanan jangka panjang 25 tahun (A2, G3) | 123450022 |
| K-04-003 | 2026-11-14 | State remote S3 terenkripsi AES256, hak baca terbatas untuk tim platform (14 orang), dan larangan kredensial di state | Melindungi blueprint rahasia (A1, E6); mencegah kebocoran kunci API 140 kios antrean (A4, A5); menargetkan RPO ≤ 1 jam (S5) | 123450022 |
