provider "aws" {
  region = var.region

  # Label G4 ikut ke setiap resource yang dapat diberi tag: showback dan aturan tata kelola
  # membaca tag ini, bukan nama resource.
  default_tags {
    tags = {
      kursus        = "komputasi-awan"
      nim           = var.nim
      kelompok      = var.kelompok
      modul         = "m07"
      stack         = "m07-integrasi"
      "managed-by"  = "opentofu"
      owner         = var.nim
      lingkungan    = var.lingkungan
      "cost-center" = var.cost_center
      "data-class"  = var.data_class
      penerap       = var.penerap
      run           = var.run_id
    }
  }
}
