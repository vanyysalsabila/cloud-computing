# Modul 05 — Laporan Audit Keamanan

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |
| Peninjau PR `m05` (NIM) | 123450001 |
| Tautan *pull request* | `https://github.com/vanysalsabila/koma-infra/pull/5` |

Isi berkas ini sambil mengerjakan prosedur. Jangan menulis password, passphrase state, token verifier, isi state atau plan JSON, atau 12 digit ID akun AWS; tulis nama bucket sebagai `koma-<nim>-m05-laporan-<akun>`. Berkas ini ikut di-commit dan masuk `koma-module-05.zip`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| `tofu apply` stack `m00-pagar` (ringkasan baris terakhir) | `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` |
| `aws s3control get-public-access-block` (keempat pengaturan) | `BlockPublicAcls: true`, `IgnorePublicAcls: true`, `BlockPublicPolicy: true`, `RestrictPublicBuckets: true` |
| `tofu apply` stack `m00-verifier` setelah `izin-m05.tf` (ringkasan) | `Apply complete! Resources: 4 added, 0 changed, 0 destroyed.` (termasuk `aws_iam_role_policy.baca_m05`) |
| Impor yang diperlukan (bila ada) | Tidak ada (`NoSuchPublicAccessBlockConfiguration` sebelum `m00-pagar` diterapkan; `m00-state` dibangun ulang terlebih dahulu) |
| Sidik jari passphrase state (8 karakter awal SHA-256, bukan passphrase-nya) | `99a3a354` |
| Tempat Anda menyimpan salinan passphrase (jenis, bukan isinya) | Berkas lokal `~/.koma/kunci-state-m05` (`chmod 600`, di luar repo Git) |
| Komputer yang dipakai sesi ini (PC lab nomor / laptop) | Laptop pribadi (macOS arm64) |
| `conftest --version`, `trivy --version` | `Conftest: 0.71.1` (`OPA: 1.21.1`), `Version: 0.76.2` |

## Tabel Audit

Satu baris per temuan stack `m05-rawan` (ada enam). Nomor baris merujuk berkas di `stacks/m05-rawan/`.

| # | Temuan (berkas:baris) | Kebutuhan dilanggar | Ancaman ([S] §6.4, hlm.) | Perbaikan di `m05-aman` |
|---|---|---|---|---|
| 1 | `main.tf:36-47` (`aws_iam_role_policy.api`: `Action = "*"`, `Resource = "*"`) | Hak akses minimal (*least privilege*) / `iam_minimal` | Eskalasi hak akses (*privilege escalation*) & pergerakan lateral jika instance/IMDS disusupi (§6.4) | Ganti dengan dua kebijakan sempit: `ssm:GetParameter` pada satu ARN parameter & `kms:Decrypt` pada kunci `m05` bersyarat `kms:ViaService`, serta wajibkan IMDSv2 (`main.tf:79-148`) |
| 2 | `main.tf:63-70` (`aws_vpc_security_group_ingress_rule.ssh`: port 22 terbuka ke `0.0.0.0/0`, serta HTTP `0.0.0.0/0` & egress `-1` di `72-85`) | Batas jaringan minimal (`sg_terbatas`) | Eksploitasi port administrasi dari internet publik & akses tanpa batas ke host (§6.4) | Hapus aturan SSH `0.0.0.0/0`; batasi ingress HTTP 80 hanya dari `var.cidr_saya` (`/32`) dan egress hanya HTTPS 443 (`main.tf:127-166`) |
| 3 | `variables.tf:27-31` (`variable "db_password"` memiliki `default = "koma123"`) | Pemisahan rahasia dari kode sumber (`rahasia_securestring`) | Kebocoran kredensial lewat repositori Git, klona kontraktor, dan riwayat commit (§6.4) | Hapus literal password dari kode; bangkitkan acak via `random_password.db` dan simpan di SSM `SecureString` terenkripsi KMS `m05` (`main.tf:49-73`) |
| 4 | `outputs.tf:5-7` (`output "db_password"` mencetak `var.db_password` tanpa `sensitive = true`) | Kerahasiaan keluaran & log operasional | Kebocoran rahasia ke layar terminal, log CI/CD, dan berkas output/plan (§6.4) | Hapus output password; ganti dengan `parameter_rahasia` (hanya nama parameter SSM, bukan nilainya) dan `kunci_kms` (`outputs.tf:1-19`) |
| 5 | `main.tf:95-99` & `templates/cloud-init.yaml.tftpl:17` (`KOMA_DB_PASSWORD=${db_password}` di `user_data`, plus tanpa IMDSv2 & root disk tak terenkripsi) | User data bersih dari rahasia (`userdata_bersih`, `imdsv2`) | Pembacaan rahasia plaintext melalui `ec2:DescribeInstanceAttribute`, IMDSv1 SSRF, atau state/plan (§6.4) | Muat rahasia saat runtime lewat `ExecStartPre` (`koma-rahasia.sh` -> `/etc/koma/db.env` mode `0600`), wajibkan IMDSv2, dan enkripsi root volume (`main.tf:172-210`) |
| 6 | `main.tf:113-134` (`aws_s3_bucket_public_access_block.laporan` semua `false` & `aws_s3_bucket_policy.laporan` `Principal = "*"` pada data `rahasia`) | Privasi object storage & enkripsi at-rest/in-transit (`bucket_privat`, `blok_publik_akun`) | Kebocoran data sensitif publik / paparan tautan tanpa autentikasi (§6.4) | Aktifkan `m00-pagar` (blok publik tingkat akun), atur keempat blok publik bucket `true`, `BucketOwnerEnforced`, enkripsi `aws:kms` kunci `m05`, dan policy `Deny` tanpa TLS (`main.tf:216-283`) |

## Hasil Trivy

Perintah yang dijalankan dan versinya: `trivy config --skip-check-update .` (`Trivy 0.76.2`, embedded checks)

Satu baris per ID temuan. Untuk `m05-aman`, tulis temuan yang diterima lewat `trivy:ignore` beserta alasannya.

| Stack | ID temuan | Severity | Sesuai temuan Tabel Audit no. (atau "tambahan") | Relevan? Alasan |
|---|---|---|---|---|
| `m05-rawan` | `AWS-0028` | HIGH | Tambahan (terkait #5 — tanpa IMDSv2) | Ya; tanpa IMDSv2, skrip/SSRF dapat mengambil kredensial role IAM instance. |
| `m05-rawan` | `AWS-0086`, `AWS-0087`, `AWS-0091`, `AWS-0093` | HIGH | #6 (empat pengaturan `public_access_block` = `false`) | Ya; membuka peluang ACL maupun bucket policy publik untuk data `rahasia`. |
| `m05-rawan` | `AWS-0089` | LOW | Tambahan (S3 access logging mati) | Rendah untuk sandbox uji; tidak mengancam privasi langsung karena akses publik diblokir. |
| `m05-rawan` | `AWS-0090` | MEDIUM | Tambahan (S3 versioning mati) | Moderat untuk produksi (mencegah hapus/timpa tak sengaja); untuk m05 fokusnya privasi & enkripsi KMS. |
| `m05-rawan` | `AWS-0104` | CRITICAL | #2 (egress `0.0.0.0/0` semua protokol `-1`) | Ya; instance dapat menghubungi internet bebas ke mana saja jika disusupi. |
| `m05-rawan` | `AWS-0107` | HIGH | #2 (ingress SSH port 22 dari `0.0.0.0/0`) | Ya; membuka akses brute-force SSH dari seluruh internet. |
| `m05-rawan` | `AWS-0124` | LOW | Tambahan (egress SG tanpa `description`) | Informasi administratif untuk dokumentasi aturan jaringan. |
| `m05-rawan` | `AWS-0131` | HIGH | Tambahan (terkait #5 — root EBS volume tidak terenkripsi) | Ya; data sementara maupun `/etc/koma/db.env` wajib terenkripsi saat diam. |
| `m05-rawan` | `AWS-0132` | HIGH | #6 (bucket laporan tidak memakai SSE-KMS CMK) | Ya; data berlabel `rahasia` harus dienkripsi dengan kunci KMS milik sendiri. |
| `m05-aman` | `AVD-AWS-0104` (`trivy:ignore`) | CRITICAL | Diterima secara sadar di `m05-aman/main.tf:158` | Egress TCP port `443` ke `0.0.0.0/0` dibutuhkan EC2 di VPC bawaan untuk menghubungi endpoint regional AWS SSM & KMS tanpa VPC Interface Endpoint berbayar per jam. |
| `m05-aman` | `AVD-AWS-0089` (`trivy:ignore`) | LOW | Diterima secara sadar di `m05-aman/main.tf:215` | Bucket log akses terpisah tidak dibuat di stack sandbox Modul 05. |
| `m05-aman` | `AVD-AWS-0090` (`trivy:ignore`) | MEDIUM | Diterima secara sadar di `m05-aman/main.tf:216` | Versioning bucket arsip telah dibahas pada Modul 04; Modul 05 berfokus pada blokir publik, TLS-only, dan SSE-KMS. |

Temuan Tabel Audit yang **tidak** dilaporkan Trivy:
Trivy (`trivy config`) tidak melaporkan temuan **#1** (`aws_iam_role_policy.api` dengan `Action = "*"`, `Resource = "*"` — dalam pemindaian embedded check kali ini tidak muncul sebagai kegagalan), **#3** (nilai bawaan `default = "koma123"` pada `variable "db_password"`), **#4** (`output "db_password"` tidak bertanda `sensitive`), dan **#5** (nilai rahasia literal `KOMA_DB_PASSWORD=${db_password}` yang dirender ke `user_data` lewat `templatefile`). Hal ini terjadi karena alat analisis statis file HCL seperti Trivy tidak merender `templatefile(...)` menjadi plan akhir dan tidak memeriksa konvensi nama variabel/output rahasia lokal; celah inilah yang ditutup oleh **Conftest (`policy/m05.rego`)**.

## Hasil Conftest

| Plan | Jumlah kegagalan | Alamat yang ditolak |
|---|---|---|
| `rawan.plan.json` | 6 | `aws_iam_role_policy.api`, `aws_instance.api`, `aws_s3_bucket_policy.laporan`, `aws_vpc_security_group_ingress_rule.ssh`, `output.db_password`, `var.db_password` |
| `aman.plan.json` | 0 | - |

Resource yang tercatat *known after apply* pada plan aman dan karena itu tidak terperiksa kebijakan:
Atribut `policy` pada `aws_iam_role_policy.dekripsi` karena bergantung pada `aws_kms_key.m05.arn` yang nilainya baru diketahui setelah kunci KMS dibuat saat `apply` (`change.after_unknown.policy = true`).

## Threat Model

| Butir | Isi untuk API laporan pada kasus kelompok Anda (sebut kode bukti A1–A6) |
|---|---|
| Aset | Data laporan & unggahan pasien KSL (rekam medis, hasil lab, klaim) berlabel **Rahasia** (**A1**, **A2**), password database RME & 12 kunci API lab mitra (**A5**), serta state OpenTofu yang memuat peta infrastruktur dan metadata akun. |
| Aktor ancaman | 1) *Insider* (dokter/staf tanpa hubungan perawatan atau 41 akun mantan dokter yang masih aktif, **A3**, **A6**); 2) Pihak luar/publik yang memperoleh tautan tanpa kedaluwarsa (**A6**); 3) Vendor/pihak ketiga dengan akses berlebih (mis. vendor kios antrean di segmen flat, **A4**); 4) Penyerang eksternal yang mengeksploitasi PC klinik atau port administrasi publik (**A3**). |
| Jalur serangan | Mengakses objek S3 laporan langsung dari URL publik (`Principal: *`), membaca password DB dari repositori Git/`user_data`/IMDSv1 atau output terminal, melakukan *brute-force* SSH port 22 yang terbuka ke `0.0.0.0/0`, serta memanfaatkan izin IAM wildcard (`*/*`) untuk eskalasi hak akses lateral ke data RME. |
| Kontrol yang sudah ada | 1) S3 Block Public Access tingkat akun (`m00-pagar`) & tingkat bucket + kebijakan `Deny` non-TLS + SSE-KMS CMK berotasi (`K-05-002`); 2) Rahasia acak di SSM `SecureString` yang diambil saat runtime via `ExecStartPre` ke `/etc/koma/db.env` (`0600`) tanpa melewati kode/`user_data` (`K-05-001`); 3) IAM *least privilege*, SG hanya port 80 dari `/32`, IMDSv2 wajib, disk root terenkripsi, enkripsi state & plan OpenTofu, serta pagar shift-left Trivy + Conftest (`K-05-003`). |
| Risiko sisa | 1) Pemegang passphrase state (`kunci_state`) atau pemegang berkas `aman.plan.json` yang belum dihapus tetap bisa mendekripsi/membaca peta infrastruktur; 2) Egress HTTPS 443 ke `0.0.0.0/0` masih terbuka ke internet (tidak memakai VPC Endpoint privat); 3) Akses pada komputer bersama / sesi `aws login` aktif memberi akses setara pengguna akun; 4) Conftest belum dapat memverifikasi isi kebijakan IAM yang mengandung ARN *known after apply* sebelum `apply`. |

## Langkah dan bukti

Satu baris per `koma cek m05`. Potret aktif terakhir sebelum destroy harus lulus semua cek kecuali `bersih_akhir`, dan potret terakhir sebelum mengumpulkan harus potret bersih.

| Potret | Langkah | Keadaan | Waktu (WIB) | Hasil penting (`Latihan lulus` / `Tugas lulus`, cek yang gagal, versi parameter) |
|---|---|---|---|---|
| 1 | D.6 | stack aman berjalan | 15:34 | `Latihan lulus: True`, `Tugas lulus: False`; gagal: `rahasia_dirotasi` (versi 1), `bersih_akhir` |
| 2 | E.2 | kosong | 15:36 | `Latihan lulus: True`, `Tugas lulus: False`; `bersih_akhir` lulus (kunci KMS `PendingDeletion`); gagal: `rahasia_dirotasi` |
| 3 | Tugas Langkah 2 | dibangun ulang | 15:38 | `Latihan lulus: True`, `Tugas lulus: False`; instance `i-0305eb643a656f916`, parameter versi 1 |
| 4 | Tugas Langkah 3 | setelah rotasi dan reboot | 16:21 | `Latihan lulus: True`, `Tugas lulus: False`; `rahasia_dirotasi` LULUS (parameter versi 2), hanya `bersih_akhir` gagal |
| 5 | Tugas Langkah 5 | kosong | 16:25 | `Latihan lulus: True`, **`Tugas lulus: True`** (15/15 cek lulus; 2 kunci KMS `PendingDeletion`) |

Bukti tidak langsung yang hanya dapat diambil selama stack hidup:

| Bukti | Potret 1 | Potret 4 |
|---|---|---|
| Baris `KOMA-PENANDA` | `KOMA-PENANDA rahasia dimuat: 600 root dari /koma/123450022/m05/db-password` | `KOMA-PENANDA rahasia dimuat: 600 root dari /koma/123450022/m05/db-password` |
| Kunci tingkat atas `m05/aman.tfstate` | `['serial', 'lineage', 'meta', 'encrypted_data', 'encryption_version']` | `['serial', 'lineage', 'meta', 'encrypted_data', 'encryption_version']` |
| `describe-parameters` (tipe, versi) | `Type: SecureString`, `Version: 1` | `Type: SecureString`, `Version: 2` |
| `get-bucket-policy-status` | `"IsPublic": false` | `"IsPublic": false` |
| `curl` anonim ke objek laporan | HTTP `403` | HTTP `403` |
