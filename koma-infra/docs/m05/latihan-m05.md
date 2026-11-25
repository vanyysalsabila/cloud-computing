# Latihan 5.1 — Satu pagar, satu perbaikan

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m05.json` (setelah Bagian E, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 05**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan passphrase, isi `rawan.plan.json` atau `aman.plan.json`, atau 12 digit ID akun (tulis `<akun>`).

## 1. Pagar di dua plan

Keluaran `conftest test rawan.plan.json --policy ../../policy` (enam kegagalan):

```text

```

Keluaran `conftest test aman.plan.json --policy ../../policy`:

```text

```

## 2. Dua masukan untuk aturan 2

Isi `sg-gagal.json` (seharusnya ditolak):

```json

```

Isi `sg-lolos.json` (seharusnya lolos):

```json

```

Keluaran `conftest test sg-gagal.json sg-lolos.json --policy ../koma-infra/policy`:

```text

```

Contoh mana yang tidak ada di stack rawan, dan mengapa Anda memilihnya:

Baris kondisi Rego yang menyala pada `sg-gagal.json`, dan baris yang tidak terpenuhi pada `sg-lolos.json`:

Apakah aturan Anda sempat salah memutuskan? Bila ya, apa yang Anda ubah:

Apakah plan yang lolos Conftest pasti aman? Jawab dengan satu contoh dari D.3.2 (`after_unknown`):

## 3. Bukti tidak langsung (D.5, D.6)

| Bukti | Hasil ringkas |
|---|---|
| `get-bucket-policy-status` (`IsPublic`) | |
| `get-bucket-encryption` (algoritme, kunci) | |
| `describe-parameters` (tipe, kunci, versi; tanpa nilai) | |
| Kunci tingkat atas `m05/aman.tfstate` | |
| Baris `KOMA-PENANDA` | |
| `curl` anonim ke objek laporan (kode HTTP) | |
| `koma sehat` | |

## 4. Bukti

- Potret 1 (D.6) pada (WIB), `Latihan lulus`:
- Potret 2 (E.2, bersih) pada (WIB), `bersih_akhir`:
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m05.json` yang diunggah:
- Berkas `*.tfplan` dan `*.plan.json` sudah dihapus (E.3): ya / belum
