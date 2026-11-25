# Modul 07: verifier membaca metadata topik, antrean, fungsi, provider OIDC, role pipeline,
# dan jejak CloudTrail. Isi pesan dan isi objek arsip tidak dibaca (jumlah objek di arsip/
# dibaca lewat izin M04). Ditambahkan `koma ambil koma-m07-starter.zip`; terapkan ulang stack
# m00-verifier setelahnya.
resource "aws_iam_role_policy" "baca_m07" {
  name = "koma-baca-integrasi"
  role = aws_iam_role.verifier.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Integrasi"
        Effect = "Allow"
        Action = [
          "sns:ListTopics", "sns:GetTopicAttributes", "sns:ListSubscriptionsByTopic", "sns:GetSubscriptionAttributes",
          "sns:ListTagsForResource",
          "sqs:ListQueues", "sqs:GetQueueAttributes", "sqs:ListQueueTags",
          "lambda:ListFunctions", "lambda:GetFunctionConfiguration", "lambda:ListEventSourceMappings", "lambda:ListTags",
          "iam:ListOpenIDConnectProviders",
          "cloudtrail:LookupEvents",
        ]
        Resource = "*"
      },
      {
        Sid      = "IdentitasPipeline"
        Effect   = "Allow"
        Action   = ["iam:GetOpenIDConnectProvider", "iam:GetRole"]
        Resource = ["arn:aws:iam::*:oidc-provider/token.actions.githubusercontent.com", "arn:aws:iam::*:role/koma-${var.nim}-*"]
      },
    ]
  })
}
