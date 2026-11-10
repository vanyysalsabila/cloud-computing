# Log Keputusan

Satu baris per keputusan desain. ID berbentuk `K-<modul>-<nomor>`, misalnya `K-01-001`. Alasan
merujuk kode bukti kasus kelompok (P1–P6, E1–E8, …). Keputusan kelompok yang sama boleh muncul di
repo setiap anggota; kolom Pengusul diisi NIM anggota yang mengusulkan.

| ID | Tanggal | Keputusan | Alasan (rujuk kode bukti kasus) | Pengusul (NIM) |
|---|---|---|---|---|
| K-01-001 | 2026-11-09 | Ukuran server dikelola lewat katalog `{kecil, sedang, besar}` di `variables.tf`, bukan mengetik `instance_type` EC2 langsung | Mencegah instance berukuran tidak standar yang tidak terpantau (P5); memudahkan audit dan review PR | 123450022 |
| K-01-002 | 2026-11-09 | Refaktor dari `aws_instance.web` tunggal ke `aws_instance.layanan[*]` menggunakan blok `moved` | Server yang melayani API RME tidak boleh di-replace tanpa rencana (E4 SLA 99,95%); `moved` memastikan refaktor nama tidak memicu destroy | 123450022 |
| K-01-003 | 2026-11-09 | IMDSv2 (`http_tokens = "required"`) diwajibkan pada semua instance | Mencegah akses metadata instance dari proses yang tidak berwenang; best practice AWS Security untuk data kesehatan (A3) | 123450022 |
| K-02-001 | 2026-11-10 | Menerapkan pola AMI Baking (Golden Image) alih-alih instalasi runtime saat boot (*fry*) untuk server API | Jaringan 70 klinik dan 2 laboratorium bergantung pada VPN broadband 20-50 Mbps yang tidak stabil (E2); AMI mandiri menjamin inisialisasi instan tanpa dependensi internet luar saat rebuild darurat ≤ 4 jam (P6) | 123450022 |
| K-02-002 | 2026-11-10 | Menetapkan prinsip *Immutable Server* (pembaruan versi dilakukan dengan meluncurkan instance baru dari AMI baru, bukan in-place update) | Menghilangkan modifikasi manual dan konfigurasi drift pada server RME; mencegah terulangnya insiden P5 (server manual yang tidak terdokumentasi) | 123450022 |
| K-02-003 | 2026-11-10 | Membatasi Security Group port 80 hanya untuk prefix /32 IP pengembang (`var.cidr_saya`) | Menjaga server API sandbox dan pengujian agar tidak terpapar publik (0.0.0.0/0) sesuai kebijakan keamanan data medis KSL (A1, A3, A6) | 123450022 |
