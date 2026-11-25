# Latihan 5.1 — Satu pagar, satu perbaikan

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m05.json` (setelah Bagian E, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 05**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan passphrase, isi `rawan.plan.json` atau `aman.plan.json`, atau 12 digit ID akun (tulis `<akun>`).

## 1. Pagar di dua plan

Keluaran `conftest test rawan.plan.json --policy ../../policy` (enam kegagalan):

```text
FAIL - rawan.plan.json - main - aws_iam_role_policy.api: kebijakan IAM mengizinkan aksi wildcard (* atau <layanan>:*)
FAIL - rawan.plan.json - main - aws_instance.api: user_data memuat nilai rahasia langsung
FAIL - rawan.plan.json - main - aws_s3_bucket_policy.laporan: bucket policy mengizinkan akses publik (Principal *)
FAIL - rawan.plan.json - main - aws_vpc_security_group_ingress_rule.ssh: aturan ingress membuka akses publik ke port admin atau semua protokol
FAIL - rawan.plan.json - main - output.db_password: output rahasia tidak ditandai sensitive = true
FAIL - rawan.plan.json - main - var.db_password: variabel rahasia punya nilai bawaan

6 tests, 0 passed, 0 warnings, 6 failures, 0 exceptions
```

Keluaran `conftest test aman.plan.json --policy ../../policy`:

```text
6 tests, 6 passed, 0 warnings, 0 failures, 0 exceptions
```

## 2. Dua masukan untuk aturan 2

Isi `sg-gagal.json` (seharusnya ditolak):

```json
{
  "format_version": "1.2",
  "resource_changes": [
    {
      "address": "aws_vpc_security_group_ingress_rule.uji_gagal",
      "type": "aws_vpc_security_group_ingress_rule",
      "change": {
        "actions": ["create"],
        "after": {
          "cidr_ipv4": null,
          "cidr_ipv6": "::/0",
          "ip_protocol": "tcp",
          "from_port": 3000,
          "to_port": 4000
        }
      }
    }
  ]
}
```

Isi `sg-lolos.json` (seharusnya lolos):

```json
{
  "format_version": "1.2",
  "resource_changes": [
    {
      "address": "aws_vpc_security_group_ingress_rule.uji_lolos",
      "type": "aws_vpc_security_group_ingress_rule",
      "change": {
        "actions": ["create"],
        "after": {
          "cidr_ipv4": "0.0.0.0/0",
          "cidr_ipv6": null,
          "ip_protocol": "tcp",
          "from_port": 443,
          "to_port": 443
        }
      }
    }
  ]
}
```

Keluaran `conftest test sg-gagal.json sg-lolos.json --policy ../koma-infra/policy`:

```text
FAIL - sg-gagal.json - main - aws_vpc_security_group_ingress_rule.uji_gagal: aturan ingress membuka akses publik ke port admin atau semua protokol

12 tests, 11 passed, 0 warnings, 1 failure, 0 exceptions
```

Contoh mana yang tidak ada di stack rawan, dan mengapa Anda memilihnya:
Pada stack `m05-rawan`, aturan SSH hanya membuka port tunggal `22` dari IPv4 `0.0.0.0/0`. Di `sg-gagal.json`, saya memilih kombinasi **sumber IPv6 publik (`::/0`)** dengan **rentang port `3000..4000`** yang secara tidak langsung mencakup port admin RDP (`3389`), meskipun `from_port` maupun `to_port` bukan `3389`. Sementara itu, `sg-lolos.json` menguji trafik HTTPS (`443`) dari `0.0.0.0/0` untuk memastikan aturan tidak terlalu ketat hingga memblokir port layanan web non-admin.

Baris kondisi Rego yang menyala pada `sg-gagal.json`, dan baris yang tidak terpenuhi pada `sg-lolos.json`:
- Pada `sg-gagal.json`: `sumber_dunia(a)` terpenuhi lewat `a.cidr_ipv6 == "::/0"`, dan `mencakup_admin(a)` terpenuhi pada baris `a.from_port <= p; p <= a.to_port` untuk `p = 3389` (`3000 <= 3389 <= 4000`), sehingga aturan `deny` menyala.
- Pada `sg-lolos.json`: `sumber_dunia(a)` terpenuhi (`a.cidr_ipv4 == "0.0.0.0/0"`), tetapi `mencakup_admin(a)` **tidak terpenuhi** karena `ip_protocol` bukan `"-1"` dan tidak ada `p` dalam `{22, 3389}` yang berada di rentang `443..443`.

Apakah aturan Anda sempat salah memutuskan? Bila ya, apa yang Anda ubah:
Tidak; sejak awal `sumber_dunia` dipisah menjadi dua klausul (`cidr_ipv4 == "0.0.0.0/0"` dan `cidr_ipv6 == "::/0"`) dan pengecekan port menggunakan `is_number(a.from_port)`, `is_number(a.to_port)`, serta pertidaksamaan rentang `a.from_port <= p <= a.to_port` ditambah klausul terpisah untuk `ip_protocol == "-1"`, sehingga aman terhadap port rentang maupun nilai `null`.

Apakah plan yang lolos Conftest pasti aman? Jawab dengan satu contoh dari D.3.2 (`after_unknown`):
Tidak. Conftest hanya memeriksa atribut yang nilainya sudah diketahui pada fase `plan`. Atribut yang berada di `after_unknown` (*known after apply*) tidak terlihat oleh Rego sebelum `apply` dijalankan. Contohnya pada `aws_iam_role_policy.dekripsi`, atribut `policy` baru tersusun utuh setelah `aws_kms_key.m05.arn` tercipta saat `apply`, sehingga pada `aman.plan.json` isi kebijakan tersebut masih berada di `change.after_unknown.policy = true` dan tidak tervalidasi oleh aturan 6 Conftest sebelum `apply`.

## 3. Bukti tidak langsung (D.5, D.6)

| Bukti | Hasil ringkas |
|---|---|
| `get-bucket-policy-status` (`IsPublic`) | `"IsPublic": false` (pada `koma-123450022-m05-laporan-<akun>`) |
| `get-bucket-encryption` (algoritme, kunci) | `SSEAlgorithm: "aws:kms"`, `KMSMasterKeyID: arn:aws:kms:ap-southeast-2:<akun>:key/7decf9dc-1222-41e6-bae3-5dbde63cba01`, `BucketKeyEnabled: true` |
| `describe-parameters` (tipe, kunci, versi; tanpa nilai) | `Name: "/koma/123450022/m05/db-password"`, `Type: "SecureString"`, `KeyId: ...key/7decf9dc-...`, `Version: 1` |
| Kunci tingkat atas `m05/aman.tfstate` | `['serial', 'lineage', 'meta', 'encrypted_data', 'encryption_version']` |
| Baris `KOMA-PENANDA` | `KOMA-PENANDA rahasia dimuat: 600 root dari /koma/123450022/m05/db-password` |
| `curl` anonim ke objek laporan (kode HTTP) | `403` |
| `koma sehat` | `SEHAT setelah 0.2 detik: {'status': 'ok', 'peran': 'api', 'versi': '5.0.0'}` |

## 4. Bukti

- Potret 1 (D.6) pada `15:34` (WIB), `Latihan lulus`: `True`
- Potret 2 (E.2, bersih) pada `15:36` (WIB), `bersih_akhir`: `True`
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m05.json` yang diunggah: `latihan_lulus: true`, `sumber: "lokal"`
- Berkas `*.tfplan` dan `*.plan.json` sudah dihapus (E.3): ya
