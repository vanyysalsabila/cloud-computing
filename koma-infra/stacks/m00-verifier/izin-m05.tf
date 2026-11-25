# Modul 05: verifier membaca pengaturan keamanan (bukan isi rahasia). Berkas ini ditambahkan
# `koma ambil koma-m05-starter.zip`; terapkan ulang stack m00-verifier setelahnya.
#   - blok publik tingkat akun dan status kebijakan bucket;
#   - 100 byte pertama state m05 (cukup untuk membedakan state terenkripsi dari teks biasa,
#     belum mencapai bagian yang memuat nilai);
#   - metadata parameter SSM (nama, tipe, kunci, versi; tanpa nilai);
#   - status kunci KMS bertag NIM Anda;
#   - kebijakan role IAM berawalan koma-<nim>-.
resource "aws_iam_role_policy" "baca_m05" {
  name = "koma-baca-keamanan"
  role = aws_iam_role.verifier.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "PengaturanAkun"
        Effect   = "Allow"
        Action   = ["s3:GetAccountPublicAccessBlock", "ssm:DescribeParameters"]
        Resource = "*"
      },
      {
        Sid      = "AwalStateM05"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::koma-${var.nim}-tfstate-*/m05/aman.tfstate"
      },
      {
        Sid      = "StatusKunci"
        Effect   = "Allow"
        Action   = ["kms:DescribeKey", "kms:GetKeyRotationStatus"]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceTag/nim" = var.nim }
        }
      },
      {
        Sid    = "KebijakanRole"
        Effect = "Allow"
        Action = [
          "iam:GetInstanceProfile",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
        ]
        Resource = [
          "arn:aws:iam::*:role/koma-${var.nim}-*",
          "arn:aws:iam::*:instance-profile/koma-${var.nim}-*",
        ]
      },
    ]
  })
}
