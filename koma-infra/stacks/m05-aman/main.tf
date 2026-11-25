# Modul 05 — stack aman. Ikuti naskah Bagian C: setiap TODO menutup satu temuan stack rawan.
# Enkripsi state (enkripsi.tf) ditulis di Bagian D sebelum `tofu init` pertama.

data "aws_caller_identity" "saya" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_vpc" "bawaan" {
  default = true
}

locals {
  awalan    = "koma-${var.nim}-m05"
  akun      = data.aws_caller_identity.saya.account_id
  parameter = "/koma/${var.nim}/m05/db-password"
  # ARN disusun dari nilai yang sudah diketahui saat plan, agar kebijakan IAM dan bucket
  # tampil utuh di plan JSON dan dapat diperiksa Conftest sebelum apply.
  arn_parameter = "arn:aws:ssm:${var.region}:${local.akun}:parameter${local.parameter}"
  bucket        = "${local.awalan}-laporan-${local.akun}"
}

# TODO C.1  aws_kms_key.m05 (rotasi aktif, deletion_window_in_days = 7, tag peran = "kunci")
#           dan aws_kms_alias.m05 ("alias/${local.awalan}")
# TODO C.2  random_password.db (24, tanpa karakter khusus, keepers = var.putaran_rahasia) dan
#           aws_ssm_parameter.db_password (local.parameter, SecureString, key_id = kunci m05)
# TODO C.3  aws_iam_role.api (dipakai ec2.amazonaws.com) + dua aws_iam_role_policy:
#           baca_parameter (ssm:GetParameter pada local.arn_parameter) dan dekripsi
#           (kms:Decrypt pada kunci m05, syarat kms:ViaService SSM) + aws_iam_instance_profile.api
# TODO C.4  aws_security_group.api (VPC bawaan), ingress HTTP 80 hanya dari var.cidr_saya,
#           egress HTTPS 443 untuk memanggil SSM dan KMS
# TODO C.5  aws_instance.api (IP publik, instance profile, IMDSv2 wajib, disk root terenkripsi,
#           user_data dari templates/cloud-init.yaml.tftpl dengan versi, region, parameter,
#           aplikasi_gz; user_data_replace_on_change = true; tag peran = "api" dan versi)
# TODO C.6  aws_s3_bucket.laporan (local.bucket, force_destroy) + public access block (empat
#           true) + ownership BucketOwnerEnforced + enkripsi aws:kms dengan kunci m05 +
#           bucket policy Deny tanpa TLS + aws_s3_object.laporan (laporan/pelanggan-contoh.csv)
