# Latihan Mandiri di Lab — Modul 02

| Hal | Isi |
|---|---|
| Nama | Vany Salsabila Putri |
| NIM | 123450022 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

---

## L.1 — Menguji Health Check dan Versi API

Perintah pengujian dari terminal:

```bash
# 1. Dapatkan IP publik instance API dari output OpenTofu
tofu output api

# 2. Uji endpoint health check
curl -i http://<ip_publik>/health

# 3. Uji endpoint versi aplikasi
curl -i http://<ip_publik>/versi
```

Keluaran HTTP yang diharapkan:

```http
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.9.20
Date: Tue, 10 Nov 2026 04:40:00 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 58

{
  "status": "ok",
  "peran": "api",
  "versi": "v1"
}
```

**Penjelasan:**
Endpoint `/health` mengembalikan status `200` dengan JSON `{"status": "ok"}` yang menjadi syarat kelulusan cek `api_sehat` pada `koma cek m02`. Endpoint `/versi` mengembalikan nilai `v1` yang dicocokkan secara otomatis oleh verifier dengan tag `versi` pada instance EC2 (`versi_cocok`).

---

## L.2 — Verifikasi Security Group Terbatas (/32)

Keluaran pemeriksaan Security Group:

```text
Aturan Ingress Port 80:
- Protokol: TCP
- Port Rentang: 80 - 80
- Sumber: 103.xxx.xxx.xxx/32 (IP Publik Mahasiswa)
- Aturan 0.0.0.0/0: TIDAK ADA (Ditolak)
```

**Penjelasan Mengapa Port 80 Tidak Boleh Dibuka ke `0.0.0.0/0`:**
Membuka port 80 ke seluruh internet (`0.0.0.0/0`) pada server pengujian/sandbox melanggar prinsip *least privilege* dan meningkatkan risiko serangan pemindaian otomatis (*automated vulnerability scanner*), serangan *denial-of-service* (DoS), serta akses tidak sah terhadap API internal. Pada kasus Klinik Sehat Lampung (**A3**, **A4**), data medis pasien dan kunci integrasi laboratorium adalah data rahasia (**A1**). Pembatasan akses hanya ke prefix `/32` IP pengembang memastikan bahwa hanya lalu lintas sah dari pengembang yang dapat menjangkau instance.

---

## L.3 — Rilis Versi Baru (Immutable Deployment v1 -> v2)

Langkah alih versi tanpa in-place modification:

1. Ubah parameter versi pada `terraform.tfvars`:
   ```hcl
   versi = "v2"
   ```
2. Jalankan `tofu apply`:
   - OpenTofu memanggang AMI baru `koma-123450022-m02-api-v2`
   - Meluncurkan instance API baru dengan tag `versi = "v2"`
   - Menghancurkan instance API v1 lama
3. Jalankan `koma cek m02` untuk mencatat potret alih versi.

**Penjelasan Immutability:**
Instance tidak pernah diperbarui dengan cara masuk via SSH lalu menyunting kode di `/opt/koma/koma_api.py`. Setiap perubahan kode atau konfigurasi selalu melahirkan artefak baru (AMI baru) dan instance baru. Hal ini menjamin bahwa seluruh server produksi identik 100% dengan artefak build, tidak ada akumulasi sampah konfigurasi (*configuration drift*), dan proses *rollback* dapat dilakukan seketika hanya dengan menunjuk ID AMI sebelumnya.
