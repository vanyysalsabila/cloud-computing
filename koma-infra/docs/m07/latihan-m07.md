# Latihan 7.1 — Satu kode, dua lingkungan, satu pesan beracun

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m07.json` (setelah Bagian G, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 07**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan token verifier, isi state, atau 12 digit ID akun (tulis `<akun>`).

## 1. Dua plan, satu kode (B.2)

| Hal | dev | prod | Baris di `env/*.tfvars` penyebabnya |
|---|---|---|---|
| Resource yang dibuat (baris `Plan:`) | | | |
| Memori fungsi (MB) | | | |
| DLQ (`-gagal`) | | | |
| Retensi arsip (hari) | | | |
| `cost-center` | | | |
| `data-class` | | | |
| Anggaran (USD) | | | |

Mengapa modul tidak memerlukan satu pun `if lingkungan == "prod"`:

## 2. Satu pesan beracun, dua nasib (D.1, D.2)

Potongan log prod (baris `gagal` dengan `messageId` yang sama):

```text

```

Potongan log dev:

```text

```

| Hal | prod | dev |
|---|---|---|
| Jumlah percobaan yang terlihat | | |
| Jarak antarpercobaan (detik) | | |
| Tempat pesan berakhir | | |

Penjelasan dengan *visibility timeout*, `maxReceiveCount`, dan `batchItemFailures`:

Mengapa dua pesanan sah di batch yang sama hanya diarsipkan sekali, dan apa yang terjadi bila pesanan sah yang sama terkirim dua kali:

## 3. Showback (C.2)

Keluaran `koma showback`:

```text

```

Keluaran `koma showback semua` (bagian "Tak bertuan"):

```text

```

Apa saja yang tak bertuan, mengapa, dan pusat biaya G1 mana yang semestinya menanggungnya:

## 4. Bukti

- Potret 2 (B.3) pada (WIB), `Latihan lulus`:
- Potret 3 (D.3) pada (WIB), `dlq_menangkap`:
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m07.json` yang diunggah:
