# Uji tanpa kredensial AWS: provider aws dipalsukan (mock_provider), sehingga uji ini juga
# berjalan di job "uji" pipeline yang sengaja tidak diberi akses AWS.
#   tofu init -backend=false && tofu test

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333" }
  }
  mock_data "aws_region" {
    defaults = { region = "ap-southeast-2" }
  }
  # Atribut ARN palsu harus berbentuk ARN karena provider memeriksa bentuknya.
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:ap-southeast-2:111122223333:koma-uji-pesanan" }
  }
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:ap-southeast-2:111122223333:koma-uji-antrean"
      url = "https://sqs.ap-southeast-2.amazonaws.com/111122223333/koma-uji-antrean"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111122223333:role/koma-uji-pengarsip" }
  }
  mock_resource "aws_lambda_function" {
    defaults = { arn = "arn:aws:lambda:ap-southeast-2:111122223333:function:koma-uji-pengarsip" }
  }
}

variables {
  nim          = "121450001"
  kelompok     = "k00"
  lingkungan   = "dev"
  cost_center  = "CC-101"
  data_class   = "internal"
  ukuran       = "kecil"
  retensi_hari = 1
  dengan_dlq   = false
  anggaran_usd = 2
}

run "dev_kecil_tanpa_dlq" {
  command = apply

  assert {
    condition     = module.jalur.memori_mb == 128
    error_message = "dev memakai preset kecil (128 MB)"
  }
  assert {
    condition     = module.jalur.dlq_url == null
    error_message = "dev tidak memakai DLQ"
  }
  assert {
    condition     = output.fungsi == "koma-121450001-m07-dev-pengarsip"
    error_message = "nama fungsi mengikuti koma-<nim>-m07-<lingkungan>-pengarsip"
  }
  assert {
    condition     = anytrue([for f in aws_budgets_budget.lingkungan.cost_filter : contains(f.values, "user:cost-center$CC-101")])
    error_message = "budget disaring pada tag cost-center lingkungannya"
  }
}

# TODO C.4  run "prod_dari_kode_yang_sama" (apply, nilai prod): memori 256, DLQ ada, nama bucket
# TODO C.4  run "rahasia_di_dev_ditolak", "pusat_biaya_tak_sah", "ukuran_di_luar_preset" (plan, expect_failures)
# TODO C.4  run "prod_tanpa_dlq_diperingatkan" (plan, expect_failures = [check.prod_tangguh])
