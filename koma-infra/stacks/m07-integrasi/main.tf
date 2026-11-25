# Stack m07-integrasi: satu kode untuk dev dan prod. Yang berbeda antar lingkungan hanya
# env/<lingkungan>.tfvars dan state-nya (env/<lingkungan>.backend.hcl). Ikuti naskah.

# TODO A.5  module "jalur" (source ../../modules/antrean-arsip; awalan "koma-${var.nim}-m07-${var.lingkungan}",
#           lalu lingkungan, ukuran, retensi_hari, dengan_dlq, versi dari variabel)

# TODO C.2  aws_budgets_budget.lingkungan ("koma-${var.nim}-m07-${var.lingkungan}", COST, bulanan,
#           batas var.anggaran_usd, cost_filter TagKeyValue format("user:cost-center$%s", var.cost_center))

# TODO C.3  check "prod_tangguh": prod semestinya memakai DLQ dan ukuran sedang
