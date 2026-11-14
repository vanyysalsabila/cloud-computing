# Modul 00 — Izin S3 untuk Verifier Modul 04 (Metadata bucket dan daftar versi objek)

data "aws_iam_policy_document" "verifier_s3_m04" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketVersioning",
      "s3:GetBucketEncryption",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetLifecycleConfiguration",
      "s3:GetBucketTagging",
      "s3:ListBucket",
      "s3:ListBucketVersions"
    ]
    resources = [
      "arn:aws:s3:::koma-${var.nim}-tfstate-*",
      "arn:aws:s3:::koma-${var.nim}-m04-arsip-*"
    ]
  }
}

resource "aws_iam_role_policy" "verifier_s3_m04" {
  name   = "koma-verifier-s3-m04"
  role   = aws_iam_role.verifier.id
  policy = data.aws_iam_policy_document.verifier_s3_m04.json
}
