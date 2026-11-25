# Modul 06: verifier membaca alarm, riwayat alarm, daftar dasbor, dan metadata log group
# (nama, stream, waktu event terakhir; tanpa membaca isi log). Ditambahkan
# `koma ambil koma-m06-starter.zip`; terapkan ulang stack m00-verifier setelahnya.
resource "aws_iam_role_policy" "baca_m06" {
  name = "koma-baca-observability"
  role = aws_iam_role.verifier.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "Observability"
      Effect = "Allow"
      Action = [
        "cloudwatch:DescribeAlarms",
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:ListDashboards",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "*"
    }]
  })
}
