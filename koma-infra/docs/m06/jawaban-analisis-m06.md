# Jawaban Analisis — Modul 06 (draf)

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada **Tugas Individu — Modul 06** di Workbench. Bukti berasal dari pekerjaan Anda (`docs/m06/catatan-bukti.md`, `latihan-m06.md`, bukti verifier) dan berkas kasus kelompok. Sebut kode bukti kasus (L1–L5, E4, E5, E8, O1–O6) saat memakai faktanya, dan rujuk baris `K-06-*` bila relevan. Angka Sumatera Data di naskah adalah contoh, bukan angka kasus Anda.

## Pertanyaan 1 — Strategi dan bukti keberhasilan

Matriks Strategi saya (ringkas):

| Komponen | Strategi | Alasan (kode bukti) |
|---|---|---|
| Aplikasi legacy (**L1**) | **Replatform / Replace bertahap via Expand–Contract** (impor dulu ke OpenTofu, lalu *blue-green* di balik satu ALB) | Alamat API tertanam permanen di firmware 140 kios antrean (pembaruan butuh ±3 bulan kunjungan teknisi, **L2**) dan toleransi jeda ≤ 2 detik (**L4**); ALB mempertahankan satu alamat sementara backend diperbarui dari `0.9.0` ke `6.0.0` (**K-06-001**) |
| Database (**E8**, **S1**, **H1**) | **Retain di private cloud** (tetap on-premises minimal 3 tahun, tidak dimigrasikan ke cloud publik) | Data rekam medis berlabel **Rahasia** (6,8 TB, **S1**) dan menurut regulasi UU PDP serta kebijakan internal identitas pasien dilarang keluar dari pusat data KSL (**A1**, **A2**, **E8**, **H1**) |
| Portal jadwal dokter publik (**E8**, **C6**) | **Rehost / Refactor ke Serverless (Cloud Run)** | Berisi data **Publik** (**A1**) tanpa menyentuh data rekam medis sehingga aman dan hemat biaya dijalankan di cloud publik (**E8**, **C6**) |
| Arsip & analytics ter-pseudonim (**E8**, **H4**, **H5**) | **Replatform ke Object Storage Cloud Publik** | Memindahkan data agregat/ter-pseudonim untuk analisis mutu layanan tanpa membocorkan identitas pasien (**P6**, **E8**) |

Mengapa strategi L1 berbeda dengan database, dan pada fase migrasi mana keputusan ini diambil ([S] hlm. 233–240):
Aplikasi legacy Sistem Antrean Pendaftaran (**L1**) bersifat *stateless* di lapisan API dan mendesak diganti karena dibuat manual pada 2019 tanpa IaC, namun terikat alamat tetap pada 140 kios (**L2**). Oleh karena itu, **L1** dimigrasi lewat impor *brownfield* lalu diganti (*replace/replatform* di balik ALB). Sebaliknya, database RME (**E8**, **S1**) menyimpan 6,8 TB data identitas pasien berlabel **Rahasia** yang terikat kebijakan kepatuhan (**A2**) dan pola trafik 65% *east-west* dengan 14 kueri per rekam medis (**E3**), sehingga harus **dipertahankan (Retain)** di *private cloud* KSL minimal 3 tahun. Pemilihan strategi per komponen ini diambil pada **Fase 3: Perancangan aplikasi** setelah **Fase 1 (Evaluasi peluang)** dan **Fase 2 (Penemuan & inventarisasi)** memetakan dependensi serta risiko kepatuhan masing-masing beban kerja.

Sinyal yang harus sudah terpantau sebelum "migrasi dan validasi" dinyatakan selesai, per lapisan ([S] hlm. 252–254; O1), dan yang tidak dapat saya pantau sebagai pengguna cloud:
1. **Lapisan Aplikasi & Pengguna**: rasio keberhasilan HTTP 200 (rasio galat **≤ 0,05%**, **O1**), latensi **p95 < 500 ms** (**E5**, **O1**), endpoint `/health` & `/versi` menjawab `6.0.0`, serta jeda peralihan **≤ 2 detik** (**L4**).
2. **Lapisan Load Balancer / Jaringan**: `HealthyHostCount >= 1` di target group `hijau`, `RequestCount` masuk di ALB `koma-123450022-m06`, dan alarm `TargetResponseTime` berstatus `OK`.
3. **Lapisan OS / Proses & Log**: log permintaan mengalir ke CloudWatch Logs (`/koma/123450022/m06/api`, stream `i-05bbd1aabb865f889`) dan penanda konsol `KOMA-PENANDA` aktif.
- **Yang tidak dapat dipantau oleh pengguna cloud**: kesehatan *hypervisor* fisik AWS, perangkat keras jaringan/rack di Availability Zone `ap-southeast-2`, dan bidang kendali internal (*control plane*) layanan terkelola ALB/CloudWatch yang sepenuhnya berada di bawah tanggung jawab penyedia cloud (*Shared Responsibility Model*).

## Pertanyaan 2 — Impor, kode, dan drift

Bukti saya (ringkasan plan impor, isi `ignore_changes`, exit code Bagian E):
- **Plan impor (B.4)**: `Plan: 3 to import, 0 to add, 3 to change, 0 to destroy.` — hanya menambahkan tag `managed-by = "opentofu"` dan `stack = "m06-migrasi"` pada `aws_instance.legacy[0]` (`i-0d36c1811f243ed17`), `aws_security_group.legacy[0]` (`sg-0ca0b03ccb4c4501d`), dan `default_tags` pada `aws_vpc_security_group_ingress_rule.legacy_http[0]` (`sgr-07c4a2cf52653dfd4`), diikuti `No changes` setelah `impor.tf` dihapus.
- **Isi `ignore_changes`**: `lifecycle { ignore_changes = [ami, user_data, user_data_base64] }` pada `aws_instance.legacy[0]` (`legacy.tf:38-40`).
- **Exit code Bagian E**: garis dasar `0` (`No changes`), setelah injeksi `aws ec2 create-tags ... diubah-manual=ya` exit code **`2`** (`Plan: 0 to add, 1 to change, 0 to destroy`), `-refresh-only` menampilkan `"Objects have changed outside of OpenTofu"`, dan setelah rekonsiliasi (`tofu apply`) kembali exit code **`0`** dengan ID instance hijau tetap `i-05bbd1aabb865f889`.

Apa yang dibuktikan plan impor, dan apa yang tidak (Morris, 2025, hlm. 124):
Plan impor yang bersih (`0 to add, 0 to destroy`, hanya perubahan tag) membuktikan bahwa **pemetaan identitas resource di AWS sesuai dengan deklarasi atribut infrastruktur di kode HCL**, sehingga state OpenTofu kini mengendalikan siklus hidup resource tersebut tanpa menggantinya. Namun, plan impor **tidak membuktikan** bahwa konfigurasi internal di dalam sistem operasi (paket, layanan systemd, berkas konfigurasi, atau data di disk yang diabaikan oleh `ignore_changes`) benar, aman, atau dapat direproduksi ulang dari nol bila instance tersebut dihancurkan.

Perubahan manual pada O5 kasus saya: tertangkap `-detailed-exitcode` atau tidak, dan mengapa (Morris, 2025, hlm. 201, 350–351; Hafner, 2025, hlm. 193–195):
Pada **O5**, saat insiden volume log penuh terjadi, operator **menambah ruang disk langsung di server tanpa catatan**. Jika perubahan itu dilakukan pada **atribut resource AWS yang dikelola OpenTofu** (misalnya memperbesar ukuran `aws_ebs_volume` dari konsol AWS atau menambah tag seperti di Bagian E), maka `tofu plan -detailed-exitcode` **tertangkap dengan exit code 2** karena API AWS melaporkan perbedaan antara state/kode dan keadaan nyata (**K-06-003**). Sebaliknya, jika operator mengubah sesuatu **di dalam guest OS** (misalnya memperluas partisi/filesystem LVM atau menyunting berkas `/etc/systemd/system/...` lewat SSH tanpa mengubah atribut resource AWS atau dengan adanya `ignore_changes`), maka OpenTofu **tidak menangkapnya** karena penyedia (*provider*) AWS hanya memantau metadata resource API, bukan isi internal OS.

## Pertanyaan 3 — Jeda, alarm, dan anggaran galat

| Ukuran | Hasil saya | Pembanding kasus (kode) |
|---|---|---|
| Jeda saat alih (probe) | `0,0` dtk (100 sampel selama *contract*, `0` gagal) | **L4**: maksimal **≤ 2 detik** (kios galat > 3 dtk) |
| Jadwal peralihan produksi | — | **L3**: **Selasa 01.00–04.00** (maks 30 mnt) pada jam sepi **00.00–05.00** |
| Waktu deteksi alarm (menit) | **3,37 menit** (`17:08:18` → `17:11:40` WIB) | **O5**: **25 menit** (menunggu 23 klinik menelepon) |
| Anggaran galat per 30 hari | — | **E4 / O1**: SLA **99,95%** = **21,6 menit / 30 hari** (`3,37 mnt` = **15,6%** anggaran) |
| Ambang alarm lab vs SLO latensi | `0,3 dtk`, `1 × 60 dtk` | **E5 / O1**: SLO **p95 < 500 ms (`0,5 dtk`)**, rasio galat ≤ 0,05% |

Analisis dan usulan perubahan (ambang, periode, alarm tambahan dari O4, penerima dari O6) beserta tawar-menawarnya (Domingus & Arundel, 2022, hlm. 303–305):
1. **Ambang & Periode Alarm Latensi**: Ambang lab `0,3 detik` (lebih ketat dari SLO `0,5 detik` di **E5**) dengan `1 × 60 detik` mendeteksi lonjakan dalam **3,37 menit**, jauh lebih cepat daripada **O5** (25 menit) sehingga menyelamatkan sisa anggaran galat bulanan **21,6 menit** (**O1**). Namun, untuk produksi KSL (khususnya beban puncak Senin 07.30–08.30 sebesar 420 req/s, **O3**), evaluasi `1 × 60 detik` pada ambang `0,3 detik` berisiko memicu *false positive / alert fatigue* akibat lonjakan sesaat. **Usulan**: pertahankan peringatan (*warning*) pada `0,35 detik` atau naikkan periode ke `2–3 × 60 detik` (atau `evaluation_periods = 2`, *2 out of 3 datapoints*) untuk pemicu *paging* malam, dengan tawar-menawar waktu deteksi bertambah ~1–2 menit (masih ≤ 5 menit **P6**) demi menurunkan gangguan tidur tim on-call.
2. **Alarm Tambahan sesuai O4**: tambahkan alarm **rasio galat HTTP 5xx > 0,05%** (**O1**, **O4**), **API mati** (`HealthyHostCount < 1`), **utilisasi volume database > 80%** (mencegah terulangnya P5/S6), dan **antrean hasil lab tertahan > 10 menit** (**O4**).
3. **Penerima & Aturan Paging sesuai O6**: sambungkan alarm ke SNS sesuai tingkat keparahan: pemanggilan malam hanya dikirim ke 1 petugas on-call bergiliran (**4 infrastruktur + 2 DBA**, **O6**) untuk alert yang berdampak langsung ke pasien (API mati, 5xx tinggi, latensi > 0,5 dtk di 6 klinik UGD 24 jam), sedangkan alert non-kritis (seperti *drift* konfigurasi atau kapasitas menuju 80%) cukup dikirim ke kanal tiket/chat jam kerja (**O4**).

## Pertanyaan 4 — Kapan contract

Syarat sebelum contract dan apa yang hilang sesudahnya (Morris, 2025, hlm. 379–381):
Sebelum melakukan *contract* (`pertahankan_legacy = false`), tim harus memastikan: (1) seluruh lalu lintas sudah beralih ke target group `hijau` (`aktif = "hijau"`) dan target `hijau` sehat; (2) periode pengamatan pasca-alih selesai tanpa anomali latensi/galat sehingga tidak perlu lagi *rollback* cepat ke `biru`; dan (3) *precondition* pada listener melindungi agar legacy tidak dibongkar sementara `aktif = "biru"`. **Yang hilang setelah *contract*** adalah target group `biru`, server legacy `i-0d36c1811f243ed17` beserta SG-nya (`6` resource dibongkar), sehingga **kemampuan *instant rollback* ke versi `0.9.0` hilang permanen**—jika terjadi bug pada `6.0.0`, pemulihan harus melalui *roll-forward* atau membangun ulang dari Git.

Satu kriteria terukur dari observability yang saya bangun, untuk kasus saya (L2, L3, L5):
Sebelum *contract* Sistem Antrean Pendaftaran (**L1–L5**), karena aplikasi melayani **35 pendaftaran baru per menit** saat sibuk (**L5**) pada **140 kios firmware tetap** (**L2**), kriteria terukur yang harus dipenuhi selama minimal **1 siklus penuh jam sibuk pagi (07.00–10.30 WIB, O2)** setelah pengalihan di jendela **Selasa 01.00–04.00 (L3)** adalah: **p95 `TargetResponseTime` ALB < 0,3 detik (di bawah SLO 0,5 detik), `HealthyHostCount >= 1`, HTTP 5xx = 0% (≤ 0,05%), dan log permintaan sukses mengalir terus-menerus ke `/koma/123450022/m06/api` tanpa galat pada antrean/penulisan data 35 transaksi/menit**.

Utang keamanan legacy yang saya temukan dan pengaruhnya pada waktu contract:
Pada Bagian A (inventarisasi `i-0d36c1811f243ed17` dan `sg-0ca0b03ccb4c4501d`), ditemukan **tiga utang keamanan**: (1) **root EBS volume `vol-0548791bf3f18422d` tidak terenkripsi (`encrypted: false`)**; (2) **aturan egress SG terbuka ke seluruh internet (`0.0.0.0/0`, protokol `-1`)** dan aturan ingress masih terpasang langsung di SG legacy; dan (3) **ketidakhadiran log terpusat** maupun status terkelola kode sebelumnya (`managed-by` tidak ada). Karena keberadaan server legacy memperbesar permukaan serangan (terlebih bila membawa data antrean 90 hari, **L5**), utang keamanan ini mendorong tim untuk **tidak menunda *contract* terlalu lama** setelah masa *burn-in* hijau terbukti stabil—sehingga segera setelah kriteria observability terpenuhi, server legacy wajib dibongkar agar infrastruktur 100% berada di versi `hijau` yang terenkripsi, terpantau CloudWatch Logs, dan terisolasi di belakang ALB (**K-06-003**).
