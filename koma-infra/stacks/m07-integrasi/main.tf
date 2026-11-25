# Stack m07-integrasi: satu kode untuk dev dan prod. Yang berbeda antar lingkungan hanya
# env/<lingkungan>.tfvars dan state-nya (env/<lingkungan>.backend.hcl). Ikuti naskah.

module "jalur" {
  source = "../../modules/antrean-arsip"

  awalan       = "koma-${var.nim}-m07-${var.lingkungan}"
  lingkungan   = var.lingkungan
  ukuran       = var.ukuran
  retensi_hari = var.retensi_hari
  dengan_dlq   = var.dengan_dlq
  versi        = var.versi
}

resource "aws_budgets_budget" "lingkungan" {
  name         = "koma-${var.nim}-m07-${var.lingkungan}"
  budget_type  = "COST"
  limit_amount = format("%.1f", var.anggaran_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_credit = false
    include_refund = false
  }

  cost_filter {
    name   = "TagKeyValue"
    values = [format("user:cost-center$%s", var.cost_center)]
  }
}

check "prod_tangguh" {
  assert {
    condition     = var.lingkungan != "prod" || (var.dengan_dlq && var.ukuran == "sedang")
    error_message = "Lingkungan prod semestinya memakai DLQ (dengan_dlq = true) dan ukuran sedang (256 MB)."
  }
}
