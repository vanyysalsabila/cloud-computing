# Latihan 1.1 — Memilih dari katalog, bukan mengetik angka

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

Berkas ini ditulis sendiri. Keluaran plan berasal dari akun AWS Anda; penjelasannya dengan kata-kata Anda
sendiri. Simpan di folder mata kuliah, di luar repo `koma-infra`, lalu unggah bersama
`bukti/bukti-m01.json` (setelah E.1, potret terakhir kosong) ke tugas **Latihan Mandiri di Lab — Modul 01**.

## L.1 — `api` naik ke ukuran `sedang`

Blok plan yang memuat baris berubah:

```text
  # aws_instance.layanan["api"] will be updated in-place
  ~ resource "aws_instance" "layanan" {
      ~ instance_type = "t3.micro" -> "t3.small"
        id            = "i-0xxxxxxxxxxxxxxxxx"
        tags          = {
            "Name"  = "koma-123450022-m01-api"
            "peran" = "api"
        }
        # (semua atribut lain tidak berubah)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Simbol `~` berarti **in-place update** — provider AWS memodifikasi atribut instance yang sudah ada
tanpa menghapus dan membuat ulang resource. Ketika `instance_type` berubah, AWS harus
**mematikan instance** (stop), mengganti jenis hardware, lalu menghidupkan kembali (start).
Proses ini menyebabkan **downtime singkat** (biasanya 1–3 menit).

Bagi server yang sedang melayani pengguna, ini berarti semua koneksi aktif ke `api` terputus
selama instance di-restart. Untuk KSL (kasus k01) dengan SLA 99,95% (anggaran galat hanya
21,6 menit/bulan, E4), downtime ini **memotong anggaran galat** dan harus dijadwalkan di
jendela pemeliharaan (Selasa 01.00–04.00, L4). Di luar jendela itu, perubahan ukuran server
yang sedang melayani kunjungan pasien RME tidak boleh dilakukan tanpa prosedur failover terlebih dahulu.

## L.2 — `web` pindah ke Debian 12 (tidak di-apply)

Blok plan dengan `must be replaced` dan `# forces replacement`, beserta baris ringkasannya:

```text
  # aws_instance.layanan["web"] must be replaced
-/+ resource "aws_instance" "layanan" {
      ~ ami           = "ami-0aaaaaaaaaaaaaaaa" -> "ami-0bbbbbbbbbbbbbbbb" # forces replacement
      ~ id            = "i-0xxxxxxxxxxxxxxxxx" -> (known after apply)
      ~ private_ip    = "172.31.x.x" -> (known after apply)
        instance_type = "t3.micro"
        tags          = {
            "Name"  = "koma-123450022-m01-web"
            "peran" = "web"
        }
        # (atribut lain...)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

**Simbol `-/+`** berarti *replace* — resource lama dihapus dan resource baru dibuat.

**Atribut pemicunya** adalah `ami`. AMI (Amazon Machine Image) merupakan atribut yang bersifat
*immutable* pada instance EC2; artinya tidak dapat diubah tanpa mengganti instance sepenuhnya.
Provider AWS menandai ini dengan `# forces replacement`.

**Yang hilang bersama instance lama**: seluruh data pada disk root (EBS boot volume) instance lama
ikut terhapus bersama instance. Semua sesi, konfigurasi runtime, dan file sementara yang belum
disimpan ke storage terpisah akan hilang permanen.

**Konsekuensinya bagi pengguna**: portal pasien dan dasbor klinik KSL (komponen `web`) tidak
dapat diakses selama proses replace berlangsung. Jika tidak ada load balancer atau instance
cadangan, ini menjadi downtime total.

**Mengapa ringkasan memuat `1 to change` dan `1 to destroy` sekaligus**: OpenTofu pertama
*membuat* instance baru (`1 to add` = terjadi di sisi AWS), kemudian *menghapus* instance lama
(`1 to destroy`). Karena operasi ini berpasangan dan satu resource logis berubah identitasnya,
ringkasan menampilkan keduanya. Jumlah resource total tidak bertambah; yang berubah hanyalah
instance fisiknya (ID, IP, storage).

## L.3 — Ukuran di luar katalog

Pesan galat `tofu plan` dengan ukuran `raksasa`:

```text
╷
│ Error: Invalid value for variable
│
│   on variables.tf line 25:
│   25: variable "layanan" {
│     ├────────────────
│     │ var.layanan is map of object with 2 elements
│
│ Ukuran hanya boleh kecil (t3.micro) atau sedang (t3.small).
│
│ This was checked by the validation rule at variables.tf:41,3-13.
╵
```

**Kapan galat ini muncul**: galat ini muncul **sebelum menghubungi AWS**, yaitu pada fase
*validation* di dalam OpenTofu itu sendiri. OpenTofu memvalidasi semua variabel dan kondisi
`validation` di `variables.tf` pada awal `tofu plan`, sebelum mengontak API AWS maupun
membandingkan state.

**Mengapa itu penting**: karena validasi dilakukan **lokal dan cepat** (tidak butuh koneksi
internet, tidak memakan quota API AWS, tidak memunculkan resource sementara). Kesalahan
konfigurasi tertangkap lebih awal dalam siklus development (shift-left), sehingga tidak ada
resource yang terlanjur dibuat di akun AWS hanya karena ukuran diketik salah. Ini juga
memaksa praktikan memilih dari katalog yang sudah disepakati tim, bukan mengetik ukuran
EC2 sembarangan yang bisa menghabiskan kredit Free plan.

## L.4 — Bukti

- Waktu `koma cek m01` (WIB): *[isi setelah menjalankan perintah di akun AWS]*
- Nomor potret: *[isi setelah `koma cek m01`]*
- `Latihan lulus` di keluaran `koma cek`: *[isi: ya / tidak]*
- Tipe instance `api` setelah apply (dari `tofu output instance`): `t3.small`
- Plan sesudah apply berakhir `exit code = 0`
