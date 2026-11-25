# Modul antrean-arsip (Modul 07, ikuti naskah Bagian A): satu jalur integrasi pesanan per lingkungan (H3, H4).
#
#   aws sns publish ─► topik -pesanan ─► antrean -antrean ─► fungsi -pengarsip ─► bucket -arsip
#                                              │ gagal 3x (bila dengan_dlq)
#                                              └──────────► antrean -gagal
#
# ARN yang dipakai kebijakan IAM disusun dari nama (bukan dari atribut resource) agar isi
# kebijakan sudah diketahui saat plan dan dapat dibaca gerbang Conftest (lihat Modul 05,
# after_unknown).

data "aws_caller_identity" "ini" {}
data "aws_region" "ini" {}

locals {
  akun         = data.aws_caller_identity.ini.account_id
  region       = data.aws_region.ini.region
  memori       = { kecil = 128, sedang = 256 }
  bucket       = "${var.awalan}-arsip-${local.akun}"
  nama_antrean = "${var.awalan}-antrean"
  arn_antrean  = "arn:aws:sqs:${local.region}:${local.akun}:${local.nama_antrean}"
  log_group    = "/aws/lambda/${var.awalan}-pengarsip"
  arn_log      = "arn:aws:logs:${local.region}:${local.akun}:log-group:${local.log_group}"
}

resource "aws_sns_topic" "pesanan" {
  name = "${var.awalan}-pesanan"

  tags = {
    peran = "topik"
  }
}

resource "aws_sqs_queue" "gagal" {
  count = var.dengan_dlq ? 1 : 0

  name                      = "${var.awalan}-gagal"
  message_retention_seconds = 345600
  sqs_managed_sse_enabled   = true

  tags = {
    peran = "dlq"
  }
}

resource "aws_sqs_queue" "antrean" {
  name                       = local.nama_antrean
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
  sqs_managed_sse_enabled    = true
  redrive_policy = var.dengan_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.gagal[0].arn
    maxReceiveCount     = 3
  }) : null

  tags = {
    peran = "antrean"
  }
}

data "aws_iam_policy_document" "antrean_dari_topik" {
  statement {
    sid     = "IzinkanDariTopik"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [aws_sqs_queue.antrean.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.pesanan.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "dari_topik" {
  queue_url = aws_sqs_queue.antrean.id
  policy    = data.aws_iam_policy_document.antrean_dari_topik.json
}

resource "aws_sns_topic_subscription" "antrean" {
  topic_arn            = aws_sns_topic.pesanan.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.antrean.arn
  raw_message_delivery = true

  depends_on = [aws_sqs_queue_policy.dari_topik]
}

resource "aws_s3_bucket" "arsip" {
  bucket        = local.bucket
  force_destroy = true

  tags = {
    peran = "arsip"
  }
}

resource "aws_s3_bucket_public_access_block" "arsip" {
  bucket                  = aws_s3_bucket.arsip.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "arsip" {
  bucket = aws_s3_bucket.arsip.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "arsip" {
  bucket = aws_s3_bucket.arsip.id

  rule {
    id     = "retensi-arsip"
    status = "Enabled"

    filter {
      prefix = "arsip/"
    }

    expiration {
      days = var.retensi_hari
    }
  }
}

resource "aws_cloudwatch_log_group" "pengarsip" {
  name              = local.log_group
  retention_in_days = 1

  tags = {
    peran = "log"
  }
}

data "aws_iam_policy_document" "lambda_percaya" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pengarsip" {
  name               = "${var.awalan}-pengarsip"
  assume_role_policy = data.aws_iam_policy_document.lambda_percaya.json

  tags = {
    peran = "role-pengarsip"
  }
}

data "aws_iam_policy_document" "pengarsip_minimal" {
  statement {
    sid = "AmbilPesan"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [local.arn_antrean]
  }

  statement {
    sid       = "TulisArsip"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.arsip.arn}/arsip/*"]
  }

  statement {
    sid = "TulisLog"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${local.arn_log}:*"]
  }
}

resource "aws_iam_role_policy" "pengarsip" {
  name   = "pengarsip-minimal"
  role   = aws_iam_role.pengarsip.id
  policy = data.aws_iam_policy_document.pengarsip_minimal.json
}

data "archive_file" "pengarsip" {
  type        = "zip"
  source_file = "${path.module}/fungsi/pengarsip.py"
  output_path = "${path.root}/.build/pengarsip-${var.lingkungan}.zip"
}

resource "aws_lambda_function" "pengarsip" {
  function_name    = "${var.awalan}-pengarsip"
  role             = aws_iam_role.pengarsip.arn
  runtime          = "python3.12"
  handler          = "pengarsip.handler"
  filename         = data.archive_file.pengarsip.output_path
  source_code_hash = data.archive_file.pengarsip.output_base64sha256
  memory_size      = local.memori[var.ukuran]
  timeout          = 10

  environment {
    variables = {
      BUCKET     = aws_s3_bucket.arsip.bucket
      LINGKUNGAN = var.lingkungan
      VERSI      = var.versi
    }
  }

  tags = {
    versi = var.versi
    peran = "pengarsip"
  }

  depends_on = [
    aws_cloudwatch_log_group.pengarsip,
    aws_iam_role_policy.pengarsip,
  ]
}

resource "aws_lambda_event_source_mapping" "antrean" {
  event_source_arn       = aws_sqs_queue.antrean.arn
  function_name          = aws_lambda_function.pengarsip.arn
  batch_size             = 10
  function_response_types = ["ReportBatchItemFailures"]
}
