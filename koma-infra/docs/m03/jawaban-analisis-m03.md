# Jawaban Analisis — Modul 03 (draf)

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |
| Modul | M03 — Jaringan sebagai Kode |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada tugas Modul 03 di Workbench. Bukti berasal dari akun, repo, dan catatan sendiri; kasusnya dari kelompok k01 (Klinik Sehat Lampung). Setiap poin analisis mengacu pada kode bukti kasus (**E3**, **E7**, **A3**, **A4**, **P5**, **P6**, **A1**, **A2**).

---

## Pertanyaan 1 — Analisis Kerentanan Segmen Flat (/24) dan Ancaman Pergerakan Lateral

**Bukti Kasus**: **E7** (setiap klinik memakai satu segmen flat /24; di pusat data, web, API, database, dan server vendor berada dalam satu segmen server tanpa partisi internal), **A3** (ancaman utama: ransomware dari PC klinik di segmen flat; insider yang membuka rekam medis tanpa hubungan perawatan), **A1** (rekam medis dan identitas pasien berlabel rahasia), **A2** (UU 27/2022 tentang Pelindungan Data Pribadi).

**Analisis & Jawaban**:
1. **Bahaya Arsitektural Segmen Datar (Flat Network)**:
   Topologi eksisting KSL di 70 klinik dan pusat data primer Bandar Lampung berada pada segmen /24 tunggal (**E7**). Dalam topologi datar tanpa partisi Layer 3/Layer 4:
   - *Failure domain* dan *broadcast domain* menyatu. Satu PC pendaftaran atau kios antrean di klinik yang terinfeksi ransomware (**A3**) dapat memindai (*network sweep*) dan menginfeksi seluruh host lain dalam satu *broadcast domain* tanpa halangan firewall.
   - Tidak ada batasan pergerakan lateral (*lateral movement*). Penyerang yang menguasai satu PC administrasi klinik dapat langsung mengirim paket TCP ke port database relasional (5432) atau API RME karena berada pada segmen routing terbuka (**E7**).
2. **Ketiadaan Defense-in-Depth**:
   Firewall hanya berada di perimeter internet dan VPN tepi (**E7**). Paradigma keamanan perimeter ini usang (*perimeter fallacy*); begitu perimeter ditembus (misalnya melalui infeksi malware dari flashdisk staf klinik atau akun bekas dokter yang belum dicabut, **P5**, **A6**), seluruh infrastruktur inti RME terbuka tanpa perlindungan internal.
3. **Solusi Segmentasi sebagai Kode**:
   Pada Modul 03, topologi flat digantikan secara fundamental dengan **VPC Multi-Tier**:
   - *Tier Publik*: Hanya memuat Application Load Balancer (ALB).
   - *Tier Privat Aplikasi*: Memuat instance API/Web RME tanpa IP publik.
   - *Tier Privat Database*: Memuat database relasional tanpa rute keluar internet sama sekali.
   Tiap tier dibatasi oleh Security Group deklaratif yang menolak semua trafik secara bawaan (*default deny*).

---

## Pertanyaan 2 — Isolasi Akses Vendor Pihak Ketiga (Kios Antrean & Lab Eksternal)

**Bukti Kasus**: **A4** (2 laboratorium mitra mengirim hasil lewat API; 14 asuransi menarik klaim; vendor kios antrean memiliki VPN permanen ke segmen server pusat), **A5** (kunci API vendor tertulis di berkas konfigurasi pada 140 kios), **L2** (140 kios antrean di 70 klinik dengan firmware kaku), **A2** (identitas pasien dilarang keluar dari pusat data KSL).

**Analisis & Jawaban**:
1. **Evaluasi Risiko Akses Eksisting**:
   Memberikan akses VPN permanen langsung ke segmen server pusat kepada pihak ketiga (vendor kios antrean, **A4**) adalah pelanggaran berat prinsip *least privilege*. Lebih kritis lagi, kunci API vendor tertulis dalam plain text di 140 kios fisik (**A5**). Bila salah satu kios di klinik pratama dibongkar secara fisik oleh pihak luar, kunci tersebut dapat disalahgunakan untuk menjangkau seluruh segmen server pusat lewat VPN permanen tersebut.
2. **Rancangan Partisi & Isolasi Jaringan**:
   - **Pemisahan Jalur Komunikasi**: Vendor kios tidak boleh memiliki konektivitas L3 langsung ke database RME maupun segmen server internal. Kios antrean hanya diizinkan berkomunikasi secara *north-south* ke endpoint API pendaftaran spesifik melalui Application Load Balancer (ALB).
   - **Enforcement Security Group (Matriks Negatif)**:
     - Aturan `alb -> db` dan `internet -> db` **DITOLAK KERAS** (port 5432 tertutup).
     - Aturan `kios/internet -> web:80` ditolak langsung; seluruh koneksi wajib melewati ALB yang memvalidasi header HTTP dan rate limit.
   - **Demilitarized Zone (DMZ) / Ingress Terkendali**:
     Laboratorium mitra (**A4**) dan asuransi hanya diberi akses ke API Gateway / ALB reverse-proxy dengan autentikasi mTLS / token rotasi, tanpa pernah masuk ke jaringan internal KSL.

---

## Pertanyaan 3 — Rekayasa Jaringan untuk Dominasi Trafik East-West (65%)

**Bukti Kasus**: **E3** (pola trafik: 35% north-south, 65% east-west; rata-rata satu kali pembukaan rekam medis memicu 14 kueri ke database), **E5** (SLA latensi p95 API RME < 500 ms), **O3** (beban puncak Senin pagi mencapai 420 req/s), **P6** (target ketersediaan 99,95%).

**Analisis & Jawaban**:
1. **Implikasi Pola Trafik 65% East-West**:
   Di KSL, pembukaan satu dokumen rekam medis oleh dokter memicu 14 kueri database secara berurutan (*back-and-forth communication*, **E3**). Saat jam sibuk pagi dengan 420 permintaan/detik (**O3**), volume interaksi *east-west* antar-server (API $\leftrightarrow$ Database $\leftrightarrow$ Worker) mencapai lebih dari 5.800 kueri per detik.
2. **Pencegahan Bottleneck Jaringan**:
   - *Lokasi Penempatan Host*: Instance Web/API dan Database ditempatkan dalam satu Virtual Private Cloud (VPC) dan Availability Zone yang berdekatan untuk meminimalkan *network hop* dan latensi propagasi lintas subnet.
   - *Arsitektur Tanpa NAT untuk Trafik Internal*: Komunikasi antar-tier privat (API ke DB) sepenuhnya berjalan melalui routing lokal VPC (10.1.0.0/16) tanpa melintasi NAT Gateway atau firewall inspeksi berat yang dapat menambah latensi antrean (*queueing delay*).
   - *Dukungan Latensi Rendah*: Dengan menjaga latensi jaringan antar-tier < 1 ms di dalam subnet VPC lokal, budget latensi aplikasi p95 < 500 ms (**E5**) dapat dialokasikan penuh untuk proses eksekusi kueri transaksi database yang kompleks.

---

## Pertanyaan 4 — Matriks Akses Keamanan (Security Group Defense-in-Depth)

**Bukti Kasus**: **P6** (menjaga SLA 99,95% dan audit akses 100%), **E7** (pembongkaran segmen flat), **A1** (kelas rahasia identitas pasien).

**Analisis & Jawaban**:
Rancangan keamanan jaringan Modul 03 mengimplementasikan isolasi berlapis (*defense-in-depth*) dengan matriks izin positif (*whitelisting*) dan penolakan negatif (*blacklisting*) berbasis Security Group ID, bukan berbasis IP subnet statis:

### Matriks Akses Keamanan Jaringan (M03)

| Asal (Source) | Tujuan (Destination) | Port / Protokol | Status Kebijakan | Alasan Teknis & Kasus KSL |
|---|---|---|---|---|
| **IP Mahasiswa / Admin (`/32`)** | `sg-alb` | 80 / TCP (HTTP) | **DIIZINKAN (Positif)** | Akses verifikasi dan klien resmi mahasiswa. Port 80 dibatasi hanya `/32`, tidak boleh dibuka ke `0.0.0.0/0`. |
| **`sg-alb`** | `sg-web` | 80 / TCP (HTTP) | **DIIZINKAN (Positif)** | ALB meneruskan lalu lintas HTTP pasien/klinik ke instance API/Web RME di subnet privat. |
| **`sg-web`** | `sg-db` | 5432 / TCP (PostgreSQL) | **DIIZINKAN (Positif)** | Instance API RME membutuhkan kueri relasional (14 kueri per rekam medis, **E3**) ke database RME. |
| **Internet (`0.0.0.0/0`)** | `sg-web` | Semua Port | **DITOLAK (Negatif)** | Server Web/API berada di subnet privat murni tanpa IP publik; tidak boleh diakses langsung dari internet. |
| **Internet (`0.0.0.0/0`)** | `sg-db` | Semua Port | **DITOLAK (Negatif)** | Database RME memuat data medis rahasia 6,8 TB (**S1**, **A1**); dilarang keras terpapar ke publik. |
| **`sg-alb`** | `sg-db` | 5432 / TCP | **DITOLAK (Negatif)** | Mencegah *direct proxy bypass*. ALB hanya boleh berbicara ke tier Web/API, tidak memiliki hak akses langsung ke database. |
| **`sg-db`** | `sg-web` | 80 / TCP | **DITOLAK (Negatif)** | Database bersifat pasif (*target only*); database tidak boleh menginisiasi koneksi balik ke tier aplikasi. |
| **Subnet Privat** | Internet (`0.0.0.0/0`) | Egress Rute Keluar | **DITOLAK (Tanpa Rute)** | Subnet privat tidak memiliki rute default ke IGW dan tanpa NAT Gateway (**tanpa_nat**), mencegah kebocoran data (*data exfiltration*) keluar sistem secara total. |
