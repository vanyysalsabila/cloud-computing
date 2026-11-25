# Jawaban Analisis — Modul 05 (draf)

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada **Tugas Individu — Modul 05** di Workbench. Bukti berasal dari pekerjaan Anda (`docs/m05/laporan-audit.md`, `latihan-m05.md`, bukti verifier) dan berkas kasus kelompok. Sebut kode bukti kasus (A1–A6) saat memakai faktanya, dan rujuk baris `K-05-*` bila relevan. Jangan menuliskan nilai rahasia atau passphrase.

## Pertanyaan 1 — Klasifikasi temuan

| # | Temuan (berkas:baris) | Kebutuhan dilanggar | Ancaman ([S] §6.4, hlm.) |
|---|---|---|---|
| 1 | `stacks/m05-rawan/main.tf:36-47` (`aws_iam_role_policy.api`: `Action = "*"`, `Resource = "*"`) | Hak akses minimal (*least privilege*) / `iam_minimal` | Eskalasi hak akses (*privilege escalation*) dan pergerakan lateral lintas layanan AWS |
| 2 | `stacks/m05-rawan/main.tf:63-70` (`aws_vpc_security_group_ingress_rule.ssh`: port 22 dari `0.0.0.0/0`, plus HTTP `0.0.0.0/0` & egress `-1`) | Isolasi jaringan dan akses administrasi terbatas (`sg_terbatas`) | Akses jaringan tidak sah, *brute-force* port administrasi dari internet |
| 3 | `stacks/m05-rawan/variables.tf:27-31` (`variable "db_password"` dengan `default = "koma123"`) | Pemisahan kredensial dari kode sumber | Kebocoran rahasia permanen dalam repositori dan riwayat Git |
| 4 | `stacks/m05-rawan/outputs.tf:5-7` (`output "db_password"` tanpa `sensitive = true`) | Kerahasiaan keluaran eksekusi IaC | Kebocoran kredensial melalui log CI/CD, terminal, dan output state |
| 5 | `stacks/m05-rawan/main.tf:95-99` & `templates/cloud-init.yaml.tftpl:17` (`KOMA_DB_PASSWORD=${db_password}` di `user_data`, tanpa IMDSv2/enkripsi disk) | Perlindungan metadata & `user_data` bersih (`userdata_bersih`, `imdsv2`) | Eksposur rahasia plaintext lewat `ec2:DescribeInstanceAttribute`, SSRF IMDSv1, atau disk tak terenkripsi |
| 6 | `stacks/m05-rawan/main.tf:113-134` (`aws_s3_bucket_public_access_block.laporan` semua `false` & `aws_s3_bucket_policy.laporan` `Principal = "*"`) | Kontrol akses privat & enkripsi storage (`bucket_privat`, `blok_publik_akun`) | Kebocoran data rahasia secara langsung ke publik tanpa autentikasi |

Temuan paling berbahaya bagi organisasi pada kasus saya, ditimbang dengan A1, A2, dan A6 (bandingkan sekurangnya dua kandidat):
Untuk Klinik Sehat Lampung (KSL), **Temuan #6 (bucket laporan S3 terbuka untuk publik lewat `Principal = "*"`)** merupakan temuan paling berbahaya secara langsung, bahkan ketika ditimbang terhadap **Temuan #1 (IAM wildcard `*/*`)**:
- Menurut **A1**, hasil lab dan laporan klinis berlabel **Rahasia**, dan menurut **A2**, data kesehatan merupakan data pribadi spesifik berdasarkan **UU No. 27/2022 (UU PDP)** yang identitas pasiennya tidak boleh keluar tanpa otorisasi serta wajib memiliki jejak audit akses (kontrak 14 asuransi mitra).
- Pada insiden **A6**, KSL pernah mengalami kebocoran tautan hasil lab tanpa kedaluwarsa yang tersebar di grup percakapan pasien dan dapat dibuka siapa saja selama 11 hari. Temuan #6 mengulang persis skenario tersebut pada tingkat infrastruktur: siapa pun di internet tanpa kredensial AWS dapat mengunduh `laporan/pelanggan-contoh.csv` secara anonim (`curl` 200 OK).
- Sebagai perbandingan, **Temuan #1 (IAM `*/*`)** juga sangat berbahaya karena memicu risiko *lateral movement* yang diperparah oleh kelemahan **A3** (insider atau 41 akun dokter yang belum dinonaktifkan) serta **A4** (vendor kios antrean), apabila penyerang berhasil masuk ke host EC2 (misalnya lewat SSH Temuan #2 atau SSRF ke IMDSv1 Temuan #5). Namun, Temuan #6 tidak memerlukan langkah eksploitasi awal apa pun untuk membocorkan data pasien ke publik seketika, sehingga dampaknya terhadap pelanggaran UU PDP (**A2**) dan reputasi langsung terjadi begitu bucket diterapkan. Kedua risiko ini ditutup sekaligus di `m05-aman` (`K-05-002` dan `K-05-003`).

## Pertanyaan 2 — Di mana rahasia berada

| Tempat | Bentuk (teks biasa / terenkripsi, dengan apa) | Siapa yang dapat membaca | Bukti saya |
|---|---|---|---|
| Dibangkitkan | Teks acak 24 karakter di memori OpenTofu saat `apply` (`random_password.db`, tanpa literal di `.tf`) | Hanya proses OpenTofu & pemegang state/kunci | `stacks/m05-aman/main.tf:49-55` |
| State `m05/aman.tfstate` | Terenkripsi penuh *client-side* (`pbkdf2` + `aes_gcm`, objek `{serial, lineage, meta, encrypted_data, encryption_version}`) | Hanya pemegang passphrase `kunci_state` (di `~/.koma/kunci-state-m05`), bahkan admin S3/verifier tidak bisa membaca isinya | `enkripsi.tf`, kunci tingkat atas `m05/aman.tfstate`: `['serial', 'lineage', 'meta', 'encrypted_data', 'encryption_version']` |
| Parameter Store | `SecureString` terenkripsi SSE-KMS memakai CMK `alias/koma-123450022-m05` | Hanya prinsipal dengan `ssm:GetParameter` + `kms:Decrypt` (`kms:ViaService = ssm...`), yakni role EC2 `koma-123450022-m05-api` dan admin akun | `describe-parameters` (`Type: SecureString`, `Version: 1` -> `2`, tanpa nilai) |
| Server (`/etc/koma/db.env`, proses) | Teks biasa di `/etc/koma/db.env` berizin `0600` milik `root`, dibaca systemd ke env proses `koma-api.service` | Hanya `root` pada instance; pengguna lain dan caller `ec2:DescribeInstanceAttribute` (`user_data`) tidak dapat melihat nilainya | Baris `KOMA-PENANDA rahasia dimuat: 600 root dari /koma/123450022/m05/db-password` |
| `aman.plan.json`, layar, log | `aman.tfplan` terenkripsi `aes_gcm`; hasil `tofu show -json` (`aman.plan.json`) berformat **teks biasa** (memuat nilai variabel termasuk `kunci_state` dan atribut plan) | Siapa pun yang memiliki akses baca berkas `aman.plan.json` sebelum dihapus | `aman.plan.json` dihapus setelah uji Conftest (E.3), output `db_password` dihapus dari `outputs.tf` |

Apa yang terjadi saat rotasi (versi parameter, server, reboot):
Saat `putaran_rahasia` dinaikkan dari `1` ke `2`, `keepers` pada `random_password.db` berubah sehingga OpenTofu membangkitkan password baru dan memperbarui `aws_ssm_parameter.db_password` ke **versi 2** di Parameter Store tanpa mengganti instance EC2 (`user_data` tidak berubah karena hanya menyimpan nama path parameter `/koma/123450022/m05/db-password`). Ketika server di-reboot (`aws ec2 reboot-instances`), unit `systemd` menjalankan `ExecStartPre=+/usr/local/bin/koma-rahasia.sh` sebagai `root`, menarik nilai versi 2 terbaru dari SSM Parameter Store, menimpa `/etc/koma/db.env` (`0600`), dan memulai ulang `koma-api.service` dengan password baru (**K-05-001**).

Mengapa `sensitive = true` tidak cukup, dan apa yang ditambahkan enkripsi state (Hafner, 2025, hlm. 67, 70, 173–177):
Atribut `sensitive = true` pada variabel atau output hanya menyamarkan (*masking*) nilai tersebut agar tidak tercetak di layar CLI/log terminal OpenTofu; nilai rahasia tetap ditulis apa adanya dalam **teks biasa** ke dalam berkas state (`terraform.tfstate`) dan berkas plan. Dengan mengaktifkan blok `encryption` pada OpenTofu (`enkripsi.tf`, menggunakan `key_provider "pbkdf2"` dan `method "aes_gcm"` dengan `enforced = true` untuk `state` dan `plan`), seluruh muatan state dan plan dienkripsi secara *client-side* dengan enkripsi terautentikasi sebelum meninggalkan mesin lokal menuju bucket S3, sehingga pembaca bucket S3 tanpa passphrase tidak dapat membaca isi rahasia maupun topologi sensitif di dalamnya (**K-05-002**).

Risiko baru yang muncul (passphrase pribadi, PC lab, plan JSON) dan cara saya menanganinya:
1. **Kehilangan passphrase (`kunci_state`)**: state terenkripsi tidak dapat dipulihkan tanpa passphrase, yang akan mengunci manajemen stack. Penanganan: menyimpan salinan passphrase secara aman di luar repo (`~/.koma/kunci-state-m05` berizin `0600`) dan tidak pernah menuliskannya ke dalam kode atau `laporan-audit.md` (hanya mencatat sidik jari SHA-256 8 karakter awal).
2. **Komputer bersama / PC lab**: passphrase yang diekspor di environment (`TF_VAR_kunci_state`) atau berkas lokal bisa tertinggal. Penanganan: menutup sesi terminal/`aws logout` dan tidak menyimpan passphrase di workspace bersama.
3. **Plan JSON (`aman.plan.json`)**: keluaran `tofu show -json` kembali menjadi teks biasa yang memuat nilai variabel sensitif. Penanganan: membatasi pemakaiannya hanya untuk pemeriksaan sesaat oleh `conftest`, masuk dalam `.gitignore`, dan langsung menghapus berkas `*.tfplan` serta `*.plan.json` setelah selesai.

Kaitan dengan satu rahasia pada A5 kasus saya (Morris, 2025, hlm. 155–158):
Pada **A5**, kasus KSL mencatat bahwa password database RME, 12 kunci API laboratorium mitra, dan khususnya **kunci API vendor kios tertanam dalam berkas konfigurasi pada 140 kios antrean**. Pola ini persis seperti menanamkan rahasia di kode/`user_data` pada `m05-rawan`: jika satu kios atau satu berkas konfigurasi bocor, rahasia tersebut tersebar permanen dan sangat sulit diganti. Dengan memusatkan rahasia di secret store terenkripsi (SSM `SecureString` + KMS) dan mengambilnya secara dinamis saat layanan dimulai (**K-05-001**), rotasi dapat dilakukan dari satu titik kendali tanpa menyentuh kode maupun menanamkan kredensial statis di setiap node.

## Pertanyaan 3 — Pagar di titik mana

| Temuan | Trivy? (ID) | Conftest? (alamat) |
|---|---|---|
| 1. IAM wildcard `*/*` | Tidak dilaporkan pada scan lokal `trivy config` | Ya (`aws_iam_role_policy.api`) |
| 2. SG ingress SSH `0.0.0.0/0` (serta egress `-1`) | Ya (`AWS-0107`, `AWS-0104`) | Ya (`aws_vpc_security_group_ingress_rule.ssh`) |
| 3. `var.db_password` punya `default` | Tidak | Ya (`var.db_password`) |
| 4. `output.db_password` tidak `sensitive` | Tidak | Ya (`output.db_password`) |
| 5. `user_data` memuat nilai rahasia langsung (plus tanpa IMDSv2 & disk tak terenkripsi) | Sebagian (`AWS-0028` IMDSv2, `AWS-0131` disk; tidak cek isi `user_data`) | Ya (`aws_instance.api` untuk `user_data`) |
| 6. Bucket S3 publik (`public_access_block = false` & `Principal = "*"`, tanpa KMS) | Ya (`AWS-0086/87/91/93`, `AWS-0132`) | Ya (`aws_s3_bucket_policy.laporan`) |

Mengapa keduanya berbeda; apa yang tidak dapat diperiksa keduanya sebelum apply (`aws_iam_role_policy.dekripsi`):
**Trivy** memeriksa kode sumber `.tf` statis terhadap katalog aturan kepatuhan/keamanan AWS umum (seperti IMDSv2, enkripsi EBS, blok publik S3, logging, versioning) tanpa merender fungsi atau ekspresi seperti `templatefile(...)` dan tanpa mengetahui aturan konvensi lokal. **Conftest** mengevaluasi hasil *plan JSON* OpenTofu (`rawan.plan.json`) menggunakan kebijakan Rego khusus organisasi (`policy/m05.rego`), sehingga mampu menangkap nilai hasil substitusi (`user_data` yang sudah terisi `"koma123"`), `default` variabel, serta `output` yang tidak `sensitive`. Namun, keduanya **tidak dapat memeriksa** atribut yang nilainya baru tercipta saat `apply` (*known after apply* / `after_unknown`), seperti `policy` pada `aws_iam_role_policy.dekripsi` di `m05-aman` yang mereferensikan `aws_kms_key.m05.arn`.

Lapisan desain (Morris, 2025, hlm. 392) dan titik alur kerja (hlm. 393–394) untuk pagar akun, Trivy, Conftest, dan verifier:
1. **Trivy (`trivy config`) — Lapisan kode sumber (pre-plan / lokal & CI)**: menangkap salah konfigurasi umum pada `.tf` secepat mungkin (*shift-left*).
2. **Conftest (`policy/m05.rego`) — Lapisan plan (post-plan / pre-apply)**: memvalidasi sumber daya yang sudah diresolusi variabelnya dan kebijakan khusus organisasi sebelum satu pun resource dibuat di AWS.
3. **Pagar akun (`m00-pagar`: S3 Block Public Access tingkat akun) — Lapisan kontrol platform/preventif di AWS**: bertindak sebagai jaring pengaman keras (*guardrail*) di level akun AWS yang mengalahkan pengaturan per bucket; walaupun kode rawan lolos atau diubah manual di konsol, bucket tetap tidak bisa dibuka ke publik.
4. **Verifier (`koma cek m05`) — Lapisan audit pasca-apply (detektif/kepatuhan runtime)**: memverifikasi keadaan nyata yang sudah berjalan di AWS (termasuk atribut yang sebelumnya *known after apply*, status rotasi KMS, IMDSv2, isi 100 byte awal state terenkripsi, dan kebersihan akhir setelah `destroy`).

Apakah pagar ini menahan terulangnya insiden A6 kasus saya (seluruhnya, sebagian, tidak), dan mengapa:
**Sebagian besar tertahan pada infrastruktur, namun tidak seluruhnya untuk level aplikasi.** Untuk bagian kebocoran bucket/objek publik langsung seperti tautan bucket S3 yang dapat diakses anonim, gabungan **Conftest aturan 1 + Trivy + `m00-pagar` tingkat akun** menutup celah tersebut secara total (*hard guardrail*) sehingga tidak ada objek S3 yang bisa diekspos publik. Namun untuk bagian lain dari **A6** — yaitu **41 akun dokter yang sudah keluar tetapi masih aktif** dan tautan aplikasi (*presigned URL* atau endpoint RME) tanpa kedaluwarsa di logika aplikasi — pagar IaC tidak otomatis menonaktifkan akun identitas pengguna (IAM/SSO/aplikasi RME) kecuali terhubung ke proses *offboarding* HRIS/IAM dan kebijakan masa berlaku token di level aplikasi.

## Pertanyaan 4 — Model keamanan

Perimeter yang masih ada di akun saya dan yang menggantikannya (Surianarayanan & Chelliah, 2023, hlm. 192–193):
Perimeter jaringan tradisional masih dipertahankan pada Security Group server (`aws_security_group.api`) yang membatasi akses masuk port 80 hanya dari satu alamat `/32` (`var.cidr_saya`) dan akses keluar hanya port 443, serta blokade akses publik S3 di level akun (`m00-pagar`). Namun, karena sistem tidak lagi mengandalkan "di dalam jaringan privat pasti aman", perimeter lama tersebut digantikan dan diperkuat oleh model keamanan berbasis identitas dan data (**Zero Trust / identity-centric security**): autentikasi via **IAM role minimal** (`ssm:GetParameter` + `kms:Decrypt` bersyarat `kms:ViaService`), wajib token sesi **IMDSv2** untuk mencegah pencurian kredensial role, **enkripsi end-to-end** (TLS in-transit, SSE-KMS at-rest untuk EBS/S3/SSM, dan client-side `aes_gcm` untuk state OpenTofu).

Yang dapat dan tidak dapat dilakukan verifier dosen (`ec2:Describe*`, 100 byte state, parameter):
Berdasarkan `stacks/m00-verifier/izin-m05.tf` dan `m05.py`:
- **Yang dapat dilakukan verifier**: membaca metadata instance, SG, IMDSv2, dan pola `user_data` (`ec2:Describe*`); memeriksa status blok publik akun & kebijakan publik bucket (`s3:GetAccountPublicAccessBlock`, `get-bucket-policy-status`); membaca daftar dan metadata parameter SSM (`ssm:DescribeParameters` — nama, tipe `SecureString`, KeyId, nomor versi); mengecek status dan rotasi kunci KMS bertag NIM (`kms:DescribeKey`, `kms:GetKeyRotationStatus`); memeriksa inline & attached policy IAM role `koma-<nim>-*`; serta membaca **100 byte pertama** objek `m05/aman.tfstate` untuk memastikan formatnya terenkripsi.
- **Yang tidak dapat dilakukan verifier**: membaca nilai rahasia `db-password` (tidak punya `ssm:GetParameter` maupun `kms:Decrypt`), membaca isi objek laporan pelanggan di bucket S3, mengubah/membuat/menghapus resource apa pun (`ReadOnly` sempit), serta membaca isi penuh state `m05/aman.tfstate` yang sudah terenkripsi passphrase milik mahasiswa.

Yang dapat dilakukan peninjau PR saya, dan siapa pun yang memegang sesi `aws login` yang tertinggal di PC lab (*insider threat*, hlm. 205):
- **Peninjau PR (`123450001`)**: hanya dapat membaca kode OpenTofu, kebijakan Rego, laporan audit, serta `bukti/bukti-m05.json` di GitHub. Ia **tidak** memiliki akses ke akun AWS saya, tidak memiliki `terraform.tfvars`, tidak memiliki `kunci_state` (`~/.koma/kunci-state-m05`), dan tidak dapat membaca nilai password di SSM maupun memodifikasi infrastruktur live saya.
- **Pemegang sesi `aws login` yang tertinggal di PC lab**: karena bertindak dengan identitas penuh pemilik akun AWS (*insider threat* dengan sesi sah), ia dapat menjalankan `aws ssm get-parameter --with-decryption` untuk melihat nilai password database, membaca objek bucket laporan, menonaktifkan `m00-pagar`, atau membuat resource liar yang membebani biaya. Itulah sebabnya `README.md` mewajibkan `aws logout` di komputer bersama, dan itulah nilai tambah enkripsi state OpenTofu (`enkripsi.tf`): meski sesi AWS disusupi, file `m05/aman.tfstate` tetap tidak dapat didekripsi tanpa passphrase lokal.

Perbandingan dengan pihak ketiga pada A4 kasus saya:
Pada **A4**, 2 laboratorium mitra, 14 asuransi, dan vendor kios antrean memiliki integrasi API dan VPN permanen ke segmen server pusat KSL. Dibandingkan role verifier (`izin-m05.tf`) yang hanya diberi izin *read-only* sangat sempit pada resource spesifik berawalan `koma-<nim>-*` atau bertag `nim` tanpa akses ke data rahasia, akses vendor kios pada kondisi eksisting KSL (**A4**, **E7**) justru berada di segmen jaringan flat bersama database dengan kunci API tertanam statis (**A5**). Oleh karena itu, model pembatasan identitas sempit seperti pada `izin-m05.tf` dan `m05-aman` (`K-05-003`) seharusnya juga diterapkan kepada pihak ketiga KSL: isolasi ke segmen/API gateway terpisah, izin hanya pada endpoint yang relevan, dan tanpa akses langsung ke jaringan atau penyimpanan data pasien.
