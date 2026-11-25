provider "aws" {
  region = var.region

  default_tags {
    tags = {
      kursus       = "komputasi-awan"
      nim          = var.nim
      kelompok     = var.kelompok
      modul        = "m06"
      stack        = "m06-migrasi"
      "managed-by" = "opentofu"
    }
  }
}
