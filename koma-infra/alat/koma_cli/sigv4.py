"""Permintaan `sts:GetCallerIdentity` bertanda tangan SigV4 (stdlib saja).

Dipakai mahasiswa yang memakai IAM user di akun dosen (`koma verifier --iam`): laptop
menandatangani permintaan ini dengan kredensialnya sendiri, tetapi TIDAK mengirimkannya ke AWS.
Permintaan itu dikirim ke verifier, yang meneruskannya ke STS. Jawaban STS (ARN IAM user)
membuktikan siapa pemanggilnya tanpa token dan tanpa kunci rahasia meninggalkan laptop.
Tanda tangan berlaku sekitar 15 menit dan hanya untuk satu aksi ini.
"""

from __future__ import annotations

import datetime as _dt
import hashlib
import hmac
from typing import Mapping

BADAN = "Action=GetCallerIdentity&Version=2011-06-15"
JENIS = "application/x-www-form-urlencoded; charset=utf-8"
#: header tambahan yang ikut ditandatangani: mengikat tanda tangan pada verifier praktikum ini
HEADER_VERIFIER = "x-koma-verifier"
PENANDA = "komputasi-awan"


def _hmac(kunci: bytes, teks: str) -> bytes:
    return hmac.new(kunci, teks.encode(), hashlib.sha256).digest()


def host_sts(region: str) -> str:
    return f"sts.{region}.amazonaws.com"


def tandatangani_caller_identity(kred: Mapping[str, str], region: str, penanda: str,
                                 waktu: _dt.datetime | None = None) -> dict:
    """Kembalikan {"url", "badan", "header"} siap dikirim ulang oleh verifier."""
    w = (waktu or _dt.datetime.now(_dt.timezone.utc)).astimezone(_dt.timezone.utc)
    amz_date, tanggal = w.strftime("%Y%m%dT%H%M%SZ"), w.strftime("%Y%m%d")
    host = host_sts(region)
    header = {"content-type": JENIS, "host": host, "x-amz-date": amz_date, HEADER_VERIFIER: penanda}
    if kred.get("SessionToken"):
        header["x-amz-security-token"] = kred["SessionToken"]
    nama = sorted(header)
    kanonik = "\n".join([
        "POST", "/", "",
        "".join(f"{n}:{header[n].strip()}\n" for n in nama),
        ";".join(nama),
        hashlib.sha256(BADAN.encode()).hexdigest(),
    ])
    lingkup = f"{tanggal}/{region}/sts/aws4_request"
    untuk_ttd = "\n".join(["AWS4-HMAC-SHA256", amz_date, lingkup, hashlib.sha256(kanonik.encode()).hexdigest()])
    k = _hmac(("AWS4" + kred["SecretAccessKey"]).encode(), tanggal)
    for bagian in (region, "sts", "aws4_request"):
        k = _hmac(k, bagian)
    ttd = hmac.new(k, untuk_ttd.encode(), hashlib.sha256).hexdigest()
    header["authorization"] = (f"AWS4-HMAC-SHA256 Credential={kred['AccessKeyId']}/{lingkup}, "
                               f"SignedHeaders={';'.join(nama)}, Signature={ttd}")
    header.pop("host")  # diisi ulang oleh klien HTTP dari URL
    return {"url": f"https://{host}/", "badan": BADAN, "header": header}
