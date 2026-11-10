# Jawaban Analisis — Modul 02 (draf)

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

---

## Pertanyaan 1 — Strategi Provisioning: Bake vs. Fry

**Pertanyaan:**
Bandingkan pendekatan *bake* (memanggang image/AMI terlebih dahulu) dan *fry* (konfigurasi saat instance boot via cloud-init/script) untuk kebutuhan ekspansi 24 server API RME dan 70 server cache di klinik KSL (**C3**). Pendekatan mana yang dipilih tim platform dan mengapa?

**Jawaban:**
1. **Pendekatan Fry (Konfigurasi saat Boot):**
   * *Mekanisme*: Instance diluncurkan dari AMI dasar umum (misal Amazon Linux polos), kemudian script `cloud-init` mengunduh paket dependensi runtime, mengkloning repositori kode aplikasi, mengonfigurasi systemd, dan menyalakan service.
   * *Kelemahan pada kasus KSL*: Jaringan penghubung 70 klinik pratama dan 2 laboratorium menggunakan broadband 20–50 Mbps dengan backup LTE yang rentan fluktuasi (**E2**). Bila terjadi lonjakan trafik pagi (Senin 07.30–08.30 mencapai 420 req/s, **O3**) dan sistem perlu meluncurkan server baru secara cepat, proses *fry* membutuhkan waktu 5–10 menit per server dan berisiko gagal di tengah jalan jika unduhan paket eksternal gagal.
2. **Pendekatan Bake (Image Baking / Golden AMI):**
   * *Mekanisme*: Seluruh dependensi, konfigurasi service, dan kode aplikasi `koma_api.py` sudah diinstal dan diuji di instance pembangun, lalu dipadatkan menjadi AMI mandiri (`koma-123450022-m02-api-v1`).
   * *Keunggulan*: Instance API baru dapat menyala dan langsung beroperasi penuh dalam hitungan detik (*instant readiness*) tanpa mengunduh paket apa pun dari internet.
3. **Keputusan Tim:**
   Tim platform memilih **pendekatan Bake** (**K-02-001**). Hal ini krusial untuk memenuhi target pemulihan KSL dalam ≤ 4 jam (**P6**) dan menjaga SLA 99,95% (**E4**).

---

## Pertanyaan 2 — Arsitektur Virtualisasi: Container vs. VM

**Pertanyaan:**
Evaluasi penggunaan Virtual Machine (VM) vs. Container untuk empat komponen arsitektur KSL (**E1**): API RME, Database Relasional, Worker Notifikasi, dan Server Cache Klinik.

**Jawaban:**
1. **API RME & Pendaftaran (Stateless / Compute-bound):**
   * *Pilihan*: Pada tahap awal Modul 02 menggunakan **VM mandiri dari Golden AMI** untuk kemudahan operasional tim TI yang baru berjumlah 14 orang (**E6**). Pada evolusi arsitektur tahap lanjut (M10), komponen ini dialihkan ke **Container** agar dapat diskalakan horizontal secara elastis dari 90 ke 420 req/s (**C3**).
2. **Database Relasional RME (6,8 TB, State-heavy):**
   * *Pilihan*: **Virtual Machine (VM) / Dedicated Host**.
   * *Alasan*: Database RME membutuhkan kestabilan I/O disk lokal (**S1**), replikasi asinkron antar data center Bandar Lampung dan Metro (**E2**), serta retensi penyimpanan 25 tahun sesuai regulasi data medis (**A2**). Menjalankan database inti pada container ephemeral memperkenalkan kompleksitas pengelolaan volume persisten yang tidak sebanding dengan kapabilitas tim DBA KSL saat ini (hanya 2 orang, **E6**, **S7**).
3. **Worker & Antrean Notifikasi (Event-driven):**
   * *Pilihan*: **Container**.
   * *Alasan*: Komponen ini bersifat *stateless* dan memiliki pola beban lonjakan tajam (mengirim 30.000 pengingat serentak pada pukul 18.00, **C2**). Container memungkinkan alokasi resource instan dan skala nol (*scale to zero*) saat malam hari.
4. **Server Cache Klinik (Edge Caching di 70 Lokasi):**
   * *Pilihan*: **Container Ringan**.
   * *Alasan*: Setiap klinik hanya memiliki PC lokal dengan segmen flat /24 (**E7**). Menjalankan container cache lokal memastikan data rujukan dan jadwal dokter tetap dapat dibaca cepat oleh dokter klinik bahkan saat koneksi VPN ke data center pusat mengalami gangguan (**H6**).

---

## Pertanyaan 3 — Strategi Distribusi Konfigurasi: Push vs. Pull

**Pertanyaan:**
Dalam mengelola konfigurasi 70 server di klinik dengan jaringan VPN yang tidak stabil (**E2**), apakah model *Push* (misal Ansible controller menghubungi tiap agen) atau *Pull* (misal agen lokal berkala mengambil konfigurasi) yang lebih tahan uji?

**Jawaban:**
* **Kelemahan Model Push**: Server pusat harus membuka koneksi SSH langsung ke seluruh 70 subnet klinik. Bila koneksi LTE klinik terputus saat playbook berjalan, proses deployment akan macet (*hang*), menghasilkan status parsial (*partial failure*), dan membebani controller pusat.
* **Keunggulan Model Pull**: Setiap node klinik memiliki agen lokal yang secara berkala memeriksa pembaruan konfigurasi ke repositori terpusat. Ketika koneksi internet klinik aktif, node secara otonom menarik pembaruan dan menerapkannya secara lokal. Jika koneksi putus, node tetap beroperasi normal dengan konfigurasi terakhir tanpa mengganggu node klinik lainnya.
* **Kesimpulan**: Model **Pull** jauh lebih sesuai untuk topologi jaringan tersebar dan tidak stabil seperti KSL (**E2**).

---

## Pertanyaan 4 — Nilai Bisnis Immutable Infrastructure bagi KSL

**Pertanyaan:**
Bagaimana pola *Immutable Server* yang diterapkan di Modul 02 membantu mencegah terulangnya insiden pemicu **P5**?

**Jawaban:**
Pada insiden **P5**, sistem RME berhenti selama 190 menit karena volume log database penuh, dan operator menangani insiden secara ad-hoc dengan memperbesar disk langsung di server tanpa dokumentasi (**O5**). Dua minggu kemudian, ditemukan 41 akun dokter non-aktif yang masih tertinggal di server. Semua masalah ini berpangkal pada server yang dikelola secara manual (*mutable server* / *snowflake system*).

Dengan *Immutable Infrastructure*:
1. Tidak ada personil yang diizinkan melakukan modifikasi konfigurasi langsung (*SSH hotfix*) pada server produksi.
2. Setiap perbaikan bug atau pembaruan konfigurasi wajib melalui alur rilis kode: build AMI baru -> jalankan pengujian kesehatan -> alihkan lalu lintas -> terminate instance lama.
3. Seluruh keadaan server produksi selalu 100% konsisten dengan kode deklaratif di repositori Git, sehingga tidak ada akun liar, tidak ada skrip tersembunyi, dan sistem dapat diaudit secara transparan oleh Komite Rekam Medis (**P4**).
