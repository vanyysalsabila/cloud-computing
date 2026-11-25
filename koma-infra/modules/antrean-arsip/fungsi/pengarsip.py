"""Pengarsip pesanan: pesan SQS (dari topik SNS, raw) -> s3://<BUCKET>/arsip/<YYYY-MM-DD>/<id_pesanan>.json.

Setiap pesan diproses sendiri-sendiri. Pesan yang tidak sah (bukan JSON, field wajib hilang,
id_pesanan berbahaya sebagai nama objek) dilaporkan di batchItemFailures sehingga hanya pesan
itu yang kembali ke antrean; setelah 3 kali gagal SQS memindahkannya ke DLQ bila ada.
"""

from __future__ import annotations

import json
import os
import re
from datetime import datetime, timezone

import boto3

WAJIB = ("id_pesanan", "gerai", "total")
POLA_ID = re.compile(r"^[A-Za-z0-9-]{1,64}$")

_s3 = None


def _klien():
    global _s3
    if _s3 is None:
        _s3 = boto3.client("s3")
    return _s3


def urai(body: str) -> dict:
    data = json.loads(body)
    # Tanpa raw_message_delivery, SNS membungkus pesan di field Message.
    if isinstance(data, dict) and data.get("Type") == "Notification" and "Message" in data:
        data = json.loads(data["Message"])
    if not isinstance(data, dict):
        raise ValueError("pesan bukan objek JSON")
    hilang = [k for k in WAJIB if k not in data]
    if hilang:
        raise ValueError("field hilang: " + ", ".join(hilang))
    if not POLA_ID.match(str(data["id_pesanan"])):
        raise ValueError("id_pesanan hanya boleh huruf, angka, dan '-' (maks. 64)")
    return data


def kunci_objek(pesanan: dict) -> str:
    dibuat = str(pesanan.get("dibuat") or datetime.now(timezone.utc).isoformat())
    tanggal = dibuat[:10] if re.match(r"^\d{4}-\d{2}-\d{2}", dibuat) else datetime.now(timezone.utc).strftime("%Y-%m-%d")
    return f"arsip/{tanggal}/{pesanan['id_pesanan']}.json"


def handler(event, context):
    bucket = os.environ["BUCKET"]
    gagal = []
    for rec in event.get("Records", []):
        try:
            pesanan = urai(rec["body"])
            kunci = kunci_objek(pesanan)
            isi = {**pesanan, "lingkungan": os.environ.get("LINGKUNGAN"), "pengarsip": os.environ.get("VERSI")}
            _klien().put_object(Bucket=bucket, Key=kunci, Body=json.dumps(isi).encode("utf-8"),
                                ContentType="application/json")
            print(json.dumps({"arsip": kunci}))
        except Exception as exc:  # pesan buruk tidak boleh menggagalkan seluruh batch
            print(json.dumps({"gagal": rec.get("messageId"), "alasan": str(exc)}))
            gagal.append({"itemIdentifier": rec["messageId"]})
    return {"batchItemFailures": gagal}
