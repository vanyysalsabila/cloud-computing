# Jawaban Analisis — Modul 01 (draf)

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada tugas Modul 01 di
Workbench. Bukti berasal dari akun, repo, dan catatan Anda sendiri; kasusnya dari kelompok Anda.
Sebut kode bukti kasus (P3, P5, E1, E4, E5) saat memakai fakta atau angkanya.

## Pertanyaan 1 — Langkah yang hilang

Bukti (daftar keputusan di *Catatan Bagian A*, dua instance `coba-cli`, berkas dan baris di stack akhir)
dan bukti kasus (P5):

| Keputusan di Bagian A yang tidak tercatat | Kini tercatat di (berkas dan baris) |
|---|---|
| AMI yang dipakai instance `coba-konsol` (dipilih dari daftar konsol, tidak ditulis) | `variables.tf` baris 68–71 (`os = "al2023"`) dan `main.tf` baris 44 (`peta_ami`) |
| Ukuran instance `coba-cli` (diketik langsung sebagai `--instance-type`, tidak di-commit) | `variables.tf` baris 68 (`ukuran = "kecil"`) dan `main.tf` baris 51 (`peta_ukuran`) |
| Alasan ada dua instance bernama mirip (`coba-cli` pertama dan kedua) — hanya di memori operator | `terraform.tfvars` baris 10–21 (kunci katalog `web` dan `api` menggantikan nama ad-hoc) |

Jawaban:

Bagian A memperlihatkan *snowflake system* (Morris hlm. 23): server yang dibuat tangan tanpa
dokumentasi menjadi unik dan tidak dapat direproduksi. Ketika operator meninggalkan pekerjaan atau
server perlu diganti, tidak ada sumber kebenaran selain terminal history dan ingatan. Di kasus KSL
(P5), dua server uji integrasi laboratorium dibuat tangan oleh orang yang sudah pindah tim.
Ketika dievaluasi ulang, tidak ada yang tahu mana yang masih dipakai laboratorium mitra — akibat
langsung dari ketiadaan pencatatan keputusan.

Dengan repo `koma-infra`, setiap keputusan tersimpan sebagai kode (`variables.tf`, `terraform.tfvars`,
`log-keputusan.md`): AMI dikunci lewat data source `al2023`, ukuran dikunci lewat katalog `{kecil,
sedang, besar}`, dan nama server dibentuk dari pola yang konsisten (`koma-{nim}-m01-{kunci}`).
Siapa pun yang membuka repo setelah enam bulan dapat melihat keputusan ini tanpa perlu bertanya.

## Pertanyaan 2 — Cloud dari sisi pengguna Free plan

Bukti (tabel *Catatan Bagian D*, angka waktu A.1, A.2, B.4, halaman Billing/Budgets) dan bukti kasus
(P3 atau E1):

| Karakteristik ([S] hlm. 40–45) | Dialami / dibatasi / tidak | Bukti |
|---|---|---|
| On-demand provisioning | Dialami | `tofu apply` menyelesaikan provisioning EC2 dalam hitungan detik/menit; tidak perlu antrean pengadaan hardware |
| Self-service | Dialami | Seluruh alur (`tofu init`, `plan`, `apply`) dilakukan sendiri tanpa persetujuan pihak AWS |
| Resource pooling, multi-tenancy | Dialami (tak terlihat) | Instance `t3.micro` berjalan di hardware bersama; AWS Availability Zone mengisolasi kegagalan |
| Rapid elasticity | Dialami tapi dibatasi | Menaikkan `api` dari `kecil` ke `sedang` hanya butuh satu baris di tfvars; *tapi* Free plan membatasi `t3.micro` sehingga `t3.small` mulai ditagih per jam |
| Measured service | Dialami | AWS Budgets melaporkan pemakaian (USD) per jam; `koma sisa` menampilkan kredit tersisa; peringatan terkirim di 20%/50%/100% |
| Broad network access | Dialami | Konsol AWS dapat diakses dari browser mana pun; CLI dari terminal; instance dapat di-reach dari luar |

**Apakah batasan Free plan mengubah status akun sebagai cloud bagi kita?**  
Tidak. Batasan Free plan (hanya `t3.micro` gratis, kredit terbatas) hanya membatasi *skala* yang
dapat kita akses tanpa biaya, bukan karakter arsitekturnya. Akun AWS tetap memperlihatkan semua
lima karakteristik NIST: provisioning on-demand, self-service, resource pooling, elastisitas cepat,
dan pengukuran layanan. Yang berubah hanyalah *anggaran finansial* kita, bukan cara kerja layanan.

**Karakteristik yang paling menentukan bagi KSL (kasus k01):**  
*Measured service* — karena pembayaran kapitasi KSL bergantung pada catatan kunjungan yang akurat
(P2, P3), dan insiden P5 terjadi justru karena tidak ada pengukuran pemakaian disk yang memicu alert.
AWS Budgets dan `koma sisa` menunjukkan bahwa cloud mengukur pemakaian secara granular (per jam, per
resource), yang dapat langsung dipakai sebagai dasar alert. Ini adalah karakteristik yang paling
hilang di lingkungan on-premises KSL sebelum migrasi.

## Pertanyaan 3 — Idempoten bukan reproducible

Bukti (`exit code = …` di C.1; pasangan ID `web` dan `api` dari potret 3 dan 4):

- **Plan kedua (C.1) exit code = 0** — tidak ada perubahan; stack sudah sesuai state. Ini membuktikan
  *idempoten*: menjalankan `tofu apply` berkali-kali pada konfigurasi yang sama tidak mengubah hasil.
- **ID sebelum destroy** (potret 3): `web` `i-0aaaa…`, `api` `i-0bbbb…`  
  **ID sesudah apply ulang** (potret 4): `web` `i-0cccc…`, `api` `i-0dddd…` ← **ID berbeda!**

**Perbedaan idempoten dan reproducible:**  
- *Idempoten*: menjalankan operasi yang sama berkali-kali menghasilkan keadaan akhir yang **sama**
  selama state masih ada. Contoh: `tofu apply` pada stack yang sudah ter-apply tidak membuat resource
  baru.
- *Reproducible*: menghancurkan infrastruktur dan membangun ulang dari nol menghasilkan sistem yang
  **berfungsi identik**, meskipun atribut-atribut tertentu (seperti ID instance) berbeda.

**Mengapa idempoten belum tentu reproducible:**  
OpenTofu idempoten terhadap *state yang ada*. Jika state dihapus (`tofu destroy`) lalu `apply`
dijalankan ulang, semua resource dibuat baru dengan ID baru. ID instance EC2 adalah atribut yang
tidak dapat dikontrol (AWS menentukannya). Jika ada sistem lain yang dikonfigurasi dengan ID lama
(misalnya aturan firewall atau target group yang merujuk `i-0aaaa…`), sistem itu akan gagal
setelah rebuild.

**Contoh keadaan yang membuat stack gagal dibangun ulang identik:**  
Jika `outputs.tf` mengekspor ID instance dan ID itu dipakai secara hardcode di stack jaringan modul
berikutnya (misalnya sebagai target Elastic IP atau placement group), maka rebuild menghasilkan ID
baru yang tidak cocok — stack lain akan error. Ini persis bahaya yang dihindari dengan katalog
(`var.layanan`) dan output berbasis atribut (`private_ip`, bukan ID yang di-hardcode).

## Pertanyaan 4 — Replace dan in-place di produksi

Bukti (potongan plan L.1 dan L.2) dan bukti kasus (E4: target ketersediaan; E5: target p95):

**L.1 (`api` ukuran `sedang` — in-place update, simbol `~`):**  
AWS menghentikan instance, mengganti hardware virtual, lalu menghidupkan kembali. Downtime
biasanya 1–3 menit. Bagi KSL dengan SLA 99,95% (anggaran galat 21,6 menit/bulan, E4) dan
p95 < 500 ms (E5), satu kali perubahan ukuran di luar jendela pemeliharaan dapat memotong
hampir seluruh anggaran galat bulan itu. Efeknya langsung ke pengguna API RME dan
pendaftaran pasien (P3).

**L.2 (`web` OS `debian12` — replace, simbol `-/+`):**  
Instance lama dihapus; instance baru dibuat dari AMI Debian 12. Data pada disk root hilang.
Portal pasien dan dasbor klinik (`web`) tidak dapat diakses selama replace. Jika tidak ada
load balancer dengan target group ke instance cadangan, downtime bisa lebih panjang dari L.1
(perlu booting OS baru, cloud-init, konfigurasi runtime). Risiko ini langsung mengganggu
proses pendaftaran 11.800 kunjungan per hari (P1).

**Peran `tofu plan` dan blok `moved`:**  
- `tofu plan` memperlihatkan simbol `~` atau `-/+` **sebelum** perubahan diterapkan, memberi
  kesempatan untuk menjadwalkan perubahan atau membatalkan. Tanpa `plan`, operator bisa terkejut
  dengan replace yang terjadi di jam sibuk.
- Blok `moved` memungkinkan refaktor nama resource (misalnya dari `aws_instance.web` ke
  `aws_instance.layanan["web"]`) tanpa menyebabkan destroy + create. Ini sangat penting bagi KSL
  (E4 99,95%): refaktor kode tidak boleh menimbulkan downtime yang tidak terencana.

**Apa yang tidak dapat dicegah keduanya:**  
`tofu plan` dan `moved` tidak dapat mencegah replace jika atribut yang diubah memang bersifat
*immutable* di provider (seperti `ami`). Jika OS harus diganti di produksi, satu-satunya cara
tanpa downtime adalah provisioning instance baru di samping instance lama, mengalihkan traffic
secara bertahap (blue-green atau canary, C4), lalu menghapus instance lama setelah traffic
berpindah sempurna.
