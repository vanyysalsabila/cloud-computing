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

# TODO A.2  aws_sns_topic.pesanan ("${var.awalan}-pesanan", peran = "topik")
# TODO A.2  aws_sqs_queue.gagal (count = var.dengan_dlq ? 1 : 0; "${var.awalan}-gagal", retensi 4 hari, SSE-SQS)
#           dan aws_sqs_queue.antrean (local.nama_antrean, visibility 30 detik, retensi 1 hari, SSE-SQS,
#           redrive_policy ke DLQ setelah 3 kali bila var.dengan_dlq, null bila tidak)
# TODO A.2  aws_sqs_queue_policy.dari_topik (hanya sns.amazonaws.com dengan aws:SourceArn = topik) dan
#           aws_sns_topic_subscription.antrean (protokol sqs, raw_message_delivery, depends_on kebijakan)

# TODO A.3  aws_s3_bucket.arsip (local.bucket, force_destroy) + public access block (empat true) +
#           enkripsi AES256 + lifecycle "retensi-arsip" (prefix arsip/, kedaluwarsa var.retensi_hari)

# TODO A.4  aws_cloudwatch_log_group.pengarsip (local.log_group, retensi 1 hari)
# TODO A.4  aws_iam_role.pengarsip (dipakai lambda.amazonaws.com) + aws_iam_role_policy.pengarsip
#           "pengarsip-minimal": AmbilPesan (4 aksi sqs pada local.arn_antrean), TulisArsip
#           (s3:PutObject pada arsip/*), TulisLog (logs:CreateLogStream, PutLogEvents pada "${local.arn_log}:*")
# TODO A.4  data.archive_file.pengarsip (fungsi/pengarsip.py -> "${path.root}/.build/pengarsip-${var.lingkungan}.zip")
#           dan aws_lambda_function.pengarsip (python3.12, handler pengarsip.handler, memori
#           local.memori[var.ukuran], timeout 10, env BUCKET/LINGKUNGAN/VERSI, tag versi)
# TODO A.4  aws_lambda_event_source_mapping.antrean (batch 10, ReportBatchItemFailures)
