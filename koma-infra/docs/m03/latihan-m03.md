# Latihan Individu — Modul 03: Jaringan sebagai Kode

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |
| Tanggal | 14 November 2026 |

---

## Latihan 1 — Network Architecture Forensics

### Skenario & Bukti (Evidence Pack E1–E6)
- **E1**: Topologi tiga layer (core sepasang, 14 aggregation, 96 access switch), VLAN per departemen, Spanning Tree Protocol (STP) aktif.
- **E2**: 2.400 pengguna, 420 server.
- **E3**: Aplikasi portal, API pelacakan, database, mesin optimasi rute (memanggil database 40–60 kali per permintaan).
- **E4**: Distribusi trafik: 31% *north-south*, 69% *east-west*.
- **E5**: Riwayat insiden: 11 bulan terakhir ada 7 keluhan lambat, seluruhnya pada jam 09.00–11.00, tidak ada perangkat jatuh/rusak.
- **E6**: Proyeksi pertumbuhan: jumlah server naik 60% dalam 18 bulan.

### Tabel Analisis Forensik (Tujuh Kolom)

| Problem | Evidence | Architecture Cause | Candidate Change | Benefit | Risk | Additional Evidence |
|---|---|---|---|---|---|---|
| **Latensi lonjak & kongesti berkala pada jam 09.00–11.00 tanpa kegagalan perangkat** | **E4**, **E5**, **E3** (69% trafik *east-west*; mesin optimasi memanggil DB 40–60x per req; jam sibuk 09.00–11.00) | Topologi tradisional 3-tier (Core-Aggregation-Access) dirancang untuk pola *north-south*. Pada trafik *east-west* tinggi, paket antar-server harus naik ke layer Aggregation/Core melalui *oversubscribed uplinks*. Spanning Tree (**E1**) memblokir jalur paralel (*redundant links*), memotong kapasitas efektif hingga 50% dan memicu antrean *buffer* (*microburst congestion*). | Migrasi arsitektur data center ke **2-Tier Leaf-Spine (Clos Network)** dengan ECMP (*Equal-Cost Multi-Pathing*) Layer 3. | Jalur antar-server konsisten (*deterministic 1-hop latency*); seluruh *uplink* aktif (tanpa STP blocking); *bandwidth bisection* melimpah untuk trafik *east-west* 69%. | Kompleksitas *re-cabling*, re-addressing IP / routing underlay (BGP/EVPN-VXLAN), dan biaya pengadaan switch Spine berkecepatan tinggi. | Pola utilisasi *buffer switch* (SNMP/telemetry) dan grafik utilisasi *uplink* Aggregation-to-Core saat pukul 09.00–11.00. |
| **Penyebaran Failure Domain yang Terlalu Luas** | **E1**, **E3** (VLAN per departemen melintasi banyak switch; STP aktif) | VLAN yang membentang (*stretched L2 VLAN*) melintasi seluruh Access dan Aggregation switch. Topologi L2 rawan badai broadcast (*broadcast storm*) dan konvergensi STP yang lambat bila terjadi *link flap*. | Batasi Layer 2 hanya pada tingkat ToR (*Top of Rack / Leaf*), gunakan routing L3 / VXLAN overlay antar-Leaf. | *Failure domain* terisolasi per rak; tidak ada rekalkulasi STP global saat terjadi fluktuasi kabel/port. | Perubahan skema alokasi subnet IP server jika aplikasi masih menuntut subnet L2 datar. | *Log Syslog STP topology change notifications (TCN)* pada switch Core dan Aggregation selama jam kerja. |
| **Ketidakmampuan Menampung Ekspansi Server 60%** | **E6**, **E2** (420 server naik 60% menjadi ~672 server dalam 18 bulan) | Penambahan server pada arsitektur 3-tier akan membutuhkan ekspansi Aggregation switch yang memperparah *oversubscription ratio* ke Core dan menambah *hop count*. | Skalabilitas horisontal (*scale-out*) dengan menambah Spine switch dan Leaf switch baru sesuai kebutuhan tanpa menyentuh arsitektur inti. | Menjaga latensi tetap konstan meskipun jumlah server bertambah hingga ratusan node. | Kebutuhan kapasitas daya (*power/cooling*) dan kerapatan port di data center. | Denah rak (*rack space*), kapasitas *power distribution unit (PDU)*, dan estimasi *port count* ToR. |

---

## Latihan 2 — Flat, Hierarchical, atau Leaf-Spine?

### 1. Requirement Matrix Tiga Organisasi

| Parameter Kebutuhan | Organisasi A (Cabang Kecil) | Organisasi B (Universitas) | Organisasi C (Data Center East-West) |
|---|---|---|---|
| **Skala Perangkat** | 45 perangkat, 1 lantai | 6.800 perangkat, 11 gedung, 4 fakultas | 600 server, 1 gedung |
| **Karakteristik Trafik** | Hampir seluruhnya *north-south* (keluar ke internet/pusat) | Campuran (kantor, lab riset, mahasiswa); trafik riset *east-west* tinggi | 82% *east-west* antar-server |
| **Tuntutan Isolasi** | Tidak dituntut | Wajib antar-fakultas dan jaringan administrasi | Sangat ketat antar-tenant penelitian |
| **Kapasitas Tim TI** | 1 orang paruh waktu | 9 orang | 4 orang |
| **Laju Pertumbuhan** | Stabil | +8% per tahun | +35% per tahun |

### 2. Keputusan Arsitektur & Justifikasi

#### Organisasi A: Arsitektur Flat (Collapsed Core / Single Tier)
- **Arsitektur Terpilih**: **Collapsed Core / Flat Network** (1–2 switch layer 2/3 sederhana).
- **Justifikasi**: Skala sangat kecil (45 perangkat pada 1 lantai) dan pertumbuhan stabil. Tidak membutuhkan hierarki kompleks. Dikelola oleh 1 staf paruh waktu, sehingga kesederhanaan operasional adalah prioritas utama.
- **Arsitektur Ditolak**: Leaf-Spine dan 3-tier Hierarchical. Ditolak karena *over-engineering*, memboroskan anggaran perangkat, dan menambah beban manajemen konfigurasi yang tidak perlu.
- **Kondisi Pengubah**: Jika cabang berekspansi ke gedung bertingkat baru atau jumlah perangkat melebihi 250 node dengan segmentasi khusus.

#### Organisasi B: Arsitektur Hierarchical 3-Tier Multi-Area (dengan Pod Riset Khusus)
- **Arsitektur Terpilih**: **Hierarchical 3-Tier (Core - Distribution - Access)** untuk jaringan kampus umum, dikombinasikan dengan **Pod Leaf-Spine khusus** pada gedung Laboratorium Riset Data Center.
  - *Batas antar-wilayah*: Gedung fakultas terhubung melalui Distribution Switch ke Campus Core. Gedung riset diperlakukan sebagai Data Center Pod tersendiri yang masuk ke Core melalui routing border L3.
  - *Penjaga batas*: Firewall L3/L7 dan VLAN/VRF yang dikelola oleh tim NOC universitas (9 orang).
- **Justifikasi**: Melayani 11 gedung dan 4 fakultas dengan isolasi wajib. Struktur 3-tier memudahkan agregasi kabel per gedung dan pembatasan *broadcast domain*. Penambahan pod riset mengakomodasi beban trafik riset antar-server yang besar tanpa mengganggu trafik umum mahasiswa.
- **Arsitektur Ditolak**: Flat network menyeluruh (akan tumbang oleh *broadcast storms* dan ketiadaan isolasi 6.800 perangkat).
- **Kondisi Pengubah**: Jika seluruh laboratorium riset dialihkan ke cloud publik, maka pod Leaf-Spine internal tidak lagi dibutuhkan.

#### Organisasi C: Arsitektur 2-Tier Leaf-Spine (Clos Network)
- **Arsitektur Terpilih**: **Leaf-Spine 2-Tier** dengan BGP unnumbered / EVPN-VXLAN.
- **Justifikasi**: 82% trafik adalah *east-west* antar-server dengan laju pertumbuhan pesat (+35%/tahun). Leaf-Spine menyediakan latensi seragam (*single-hop latency* antar ToR), *bandwidth non-blocking*, dan isolasi multi-tenant penelitian menggunakan VXLAN VNI.
- **Arsitektur Ditolak**: Hierarchical 3-Tier tradisional. Ditolak karena menciptakan *oversubscription bottleneck* di Core switch pada pola trafik 82% *east-west*.
- **Kondisi Pengubah**: Jika beban kerja dialihkan ke serverless/cloud publik sehingga data center lokal hanya berfungsi sebagai penyimpanan arsip dingin.

---

## Latihan 3 — SDN Migration Decision: Analisis & Desain

### 1. Evaluasi Kebutuhan SDN
- **Penilaian**: **MIGRASI TIDAK DISARANKAN SECARA MENYELURUH (PILIH PENDEKATAN HIBRIDA / AUTOMATION-FIRST)**.
- **Alasan**:
  - Bukti E1 (frekuensi perubahan hanya 3–5 kali/bulan) menunjukkan tingkat churn jaringan yang sangat rendah. SDN controller penuh memberikan nilai tertinggi pada jaringan dinamis dengan ratusan perubahan harian (seperti cloud multi-tenant).
  - Masalah utama organisasi adalah *human error* (E2: 4 salah konfigurasi/tahun) dan *drift audit* (E3: 19 aturan menyimpang), serta waktu *provisioning* 6–9 hari (E4). Masalah-masalah ini dapat diselesaikan lebih aman dan murah menggunakan **Network as Code (Ansible/OpenTofu + GitOps)** tanpa mengganti arsitektur control plane ke SDN controller.
  - E5 (staf kuat di CLI, belum paham controller/API) dan E6 (SLA ketat 99,95% dengan penalti denda) menciptakan risiko operasional fatal bila controller gagal (*single point of failure* atau kesalahan integrasi).

### 2. Bagian Jaringan yang Dapat Diprogram
Bila SDN diadopsi secara terarah, bagian yang paling tepat diprogram adalah:
- **Edge Security & Firewall Policy**: Menerjemahkan aturan kepatuhan menjadi *security policy* seragam untuk menghapus 19 deviasi konfigurasi (E3).
- **Automasi Provisioning VLAN & Port Profil**: Mempercepat pembuatan akses aplikasi baru dari 6–9 hari kerja menjadi hitungan menit (E4).

### 3. Alur Kendali Konseptual SDN
```
[ Aplikasi / Portal Manajemen ] (Permintaan jaringan baru)
             |
       (Northbound API - REST/JSON)
             v
    [ SDN Controller Cluster ]
    +-----------------------------------------------+
    | Modul Validasi Kebijakan (Policy Engine)     |
    | Modul Topology Discovery & Path Calculation   |
    | Modul Security Compliance (Audit Engine)      |
    +-----------------------------------------------+
             |
       (Southbound API - OpenFlow / NETCONF / RESTCONF / OVSDB)
             v
[ Flow Tables / Hardware Forwarding Engines pada 340 Perangkat Jaringan ]
```

### 4. Analisis Risiko & Rencana Migrasi Bertahap
- **Risiko Utama**: *Control plane split-brain*, kurva pembelajaran tim yang curam (E5), dan pelanggaran SLA 99,95% (E6) yang berujung denda finansial.
- **Rencana Bertahap**:
  1. *Fase 1 (Bulan 1–2)*: Standardisasi CLI melalui GitOps/Ansible (mengatasi E3 dan E4 tanpa menyentuh *control plane*).
  2. *Fase 2 (Bulan 3–4)*: Pelatihan staf (E5) pada lingkungan sandbox virtual.
  3. *Fase 3 (Bulan 5–6)*: Uji coba controller SDN pada zona non-kritis (lingkungan dev/staging).
  4. *Fase 4 (Bulan 7–8)*: Migrasi bertahap data path produksi dengan skema fallback otomatis ke L3 routing tradisional bila controller hilang.
- **Metrik Validasi**: Waktu provisioning turun menjadi < 1 hari; jumlah deviasi audit kebijakan = 0; ketersediaan jaringan tetap ≥ 99,95%.

---

## Latihan 4 — Hybrid Branch Network Design

### Enam Keputusan Arsitektural

1. **Arsitektur WAN**:
   - Memakai arsitektur **Hybrid WAN** yang memadukan sirkuit privat berjaminan (MPLS/Metro-E) dan sirkuit *commodity broadband* publik dengan *overlay* terenkripsi IPsec.
2. **Relevansi SD-WAN**:
   - **Sangat Relevan**. SD-WAN Edge dipasang di kantor pusat dan 3 cabang. SD-WAN menerapkan *Dynamic Multi-Path Optimization (DMPO)* untuk memanfaatkan kedua link WAN (E4) secara aktif, mengalihkan trafik kritis dalam hitungan milidetik saat degradasi link terjadi.
3. **Fungsi Jaringan sebagai VNF (Virtual Network Functions)**:
   - *Next-Generation Firewall (NGFW)* dan *Router VPN Konsentrator* dijalankan sebagai VNF di Private Data Center untuk efisiensi lisensi dan kelincahan manajemen.
4. **Layanan Cloud Networking per Kategori**:
   - *Connectivity*: AWS Site-to-Site VPN / Transit Gateway menghubungkan DC dan kantor pusat ke VPC.
   - *Application Delivery*: Application Load Balancer (ALB) untuk mendistribusikan trafik HTTP/HTTPS ke beban kerja web/API.
   - *Protection*: Security Groups (stateful firewall per instance) dan Network ACLs (stateless filter per subnet).
5. **Strategi Pemilihan Jalur (Path Steering Policy)**:
   - *Aplikasi SaaS (48% trafik, E5)*: Diarahkan langsung ke internet melalui *Direct Internet Breakout (DIA)* lokal di tiap cabang setelah inspeksi firewall ringan, menghemat bandwidth WAN mahal.
   - *Trafik Data Pelanggan Rahasia (E6)*: Wajib melewati terowongan IPsec terenkripsi di atas link WAN berjaminan (E4) menuju DC/Cloud.
   - *Trafik Umum*: Menggunakan link broadband murah dengan fallback ke link mahal bila *packet loss* > 2% atau *jitter* > 30 ms.
6. **Skenario Kegagalan (Failure Scenarios)**:
   - *Link WAN mahal putus*: Seluruh trafik beralih otomatis ke link broadband melalui terowongan IPsec cadangan (degradasi performa minimal, keamanan tetap terjaga).
   - *Link WAN broadband putus*: Trafik SaaS sementara dialihkan melalui sirkuit mahal dengan mekanisme *traffic shaping/rate limiting* agar tidak menekan trafik data pasien.

### Tugas Tambahan: Uji Bukti Isolasi (Evidence of Isolation - E6)
- **Skenario Percobaan**: Membuktikan bahwa Virtual Network A (VLAN/VRF Tenant Pasien) tidak dapat menjangkau Virtual Network B (Tenant Umum/Tamu).
- **Perintah Pengujian**:
  ```bash
  # 1. Uji koneksi Layer 3 (ICMP) antar host lintas tenant
  ip netns exec ns-pasien ping -c 3 10.200.20.15 # IP host di ns-tamu

  # 2. Uji probe port TCP spesifik (Database / Web)
  ip netns exec ns-pasien nc -zv -w 2 10.200.20.15 80
  ip netns exec ns-pasien nc -zv -w 2 10.200.20.15 5432
  ```
- **Keluaran yang Diharapkan**:
  - `ping`: `100% packet loss` (atau `Destination Host Unreachable`).
  - `nc`: `connect to 10.200.20.15 port ... (tcp) failed: Connection timed out` (paket di-drop diam-diam).
- **Arti Kegagalan**: Jika probe menghasilkan respons TCP RST (*Connection refused*) atau *packet answered* (TTL reply), artinya isolasi partisi Layer 3 bocor pada tabel routing atau firewall, melanggar syarat kepatuhan E6 dan regulasi perlindungan data pribadi.

---

## Latihan 5 — Cloud Network Architecture Decision Memo

**KEPADA**: Direktur Teknologi & Komite Keamanan Informasi  
**DARI**: Cloud Network Architect  
**TANGGAL**: 14 November 2026  
**SUBJEK**: Cloud Network Architecture Decision Memo — Modernisasi Infrastruktur Jaringan  

### 1. Masalah (Problem) & 2. Kebutuhan (Requirements)
Organisasi menghadapi ekspansi ke tiga kota baru dalam 12 bulan (**E1**) dengan batas waktu penyelesaian 10 bulan (**E9**). Sistem didominasi trafik *east-west* sebesar 68% (**E3**) yang lahir dari interaksi intensif antar dua *service*, API, dan database (**E2**). Topologi jaringan saat ini masih berbasis *hierarchical* 3-tier dengan Spanning Tree (**E5**) serta seluruh trafik cabang dipaksa melewati MPLS mahal (**E6**). Kebutuhan utama adalah menjamin ketersediaan transaksi 99,9% (**E4**) di bawah kendala tim kecil beranggotakan 5 orang (**E7**) dan keterbatasan anggaran yang hanya mampu mendanai **satu perubahan besar** (**E8**).

### 3. Keterbatasan Saat Ini (Current Limitations)
Topologi 3-tier (**E5**) membatasi kapasitas *east-west* akibat *link blocking* STP, memicu kongesti saat beban transaksi naik. Selain itu, menyalurkan seluruh trafik cabang melalui MPLS (**E6**) memboroskan bandwidth untuk trafik non-kritis dan memperlambat pembukaan cabang di tiga kota baru (**E1**).

### 4. Arsitektur Terpilih (Architecture Chosen) & 5. Alternatif yang Ditolak (Alternatives Rejected)
* **Keputusan Utama**: Mengalihkan anggaran tunggal (**E8**) untuk **Transformasi Data Center & Cloud Core ke Arsitektur 2-Tier Leaf-Spine (Clos Network)** dengan segmentasi VPC multi-tier di cloud.
* **Alternatif yang Ditolak**: Penggantian WAN menyeluruh ke SD-WAN ditolak pada fase ini (**E8**). Memperbaiki WAN tanpa menyelesaikan bottleneck data center (**E3**, **E5**) akan membiarkan transaksi tetap lambat di pusat beban kerja. Kebutuhan cabang diatasi secara taktis dengan *IPsec VPN over Broadband* terenkripsi untuk cabang baru (**E1**).

### 6. Peran SDN, 7. Peran SD-WAN, & 8. Peran NFV
* **SDN**: Controller terprogram di cloud mengelola tabel rute dan partisi keamanan VPC secara deklaratif. Satu anggota tim yang berpengalaman dengan controller (**E7**) memimpin implementasi template IaC.
* **SD-WAN**: Diterapkan secara bertahap pada level *software agent* di cabang baru untuk *path selection* dasar tanpa investasi *appliance* fisik mahal.
* **NFV**: *Virtual Firewall* dan *Load Balancer* dijalankan sebagai fungsi tervirtualisasi terdistribusi di cloud.

### 9. Layanan Cloud Networking yang Dipakai
- **VPC & Subnet**: VPC terisolasi /16 dengan subnetting terpisah (*Tier Publik*, *Tier Web/API Privat*, *Tier Database Privat*).
- **Application Load Balancer (ALB)**: Menangani *ingress* publik dan mendistribusikan beban ke layanan mikro.
- **Security Groups & VPC Route Tables**: Menjalankan isolasi *least-privilege* tanpa membuka port keluar publik pada tier database.

### 10. Ketersediaan (Availability) & 11. Pertimbangan Operasional (Operational)
Beban kerja didistribusikan di minimal 2 Availability Zone (AZ) independen untuk memenuhi target SLA 99,9% (**E4**). Tim 5 orang (**E7**) menggunakan modul OpenTofu standar agar pemeliharaan jaringan dapat dilakukan otomatis tanpa intervensi manual.

### 12. Risiko (Risks) & 13. Asumsi (Assumptions)
- *Risiko*: Kurva pembelajaran 4 anggota tim yang belum menguasai controller (**E7**). Dimitigasi melalui penyusunan *runbook* ketat dan lingkungan staging.
- *Asumsi*: Koneksi internet lokal di tiga kota baru (**E1**) memiliki latensi < 40 ms ke cloud hub terdekat.

### 14. Rencana Validasi (Validation Plan)
Uji beban sintetis menembus 1,5x trafik puncak jam kerja; uji *failover* kabel/node Spine dengan target waktu pemulihan < 1 detik; dan audit aturan port tertutup 100%.

### 15. Kondisi yang Akan Membalik Keputusan (Reversal Condition)
Bila tarif sewa MPLS lokal turun drastis (> 70%) atau aplikasi berevolusi menjadi 80% *north-south* berbasis SaaS eksternal, prioritas investasi akan dialihkan ke optimalisasi WAN edge.
