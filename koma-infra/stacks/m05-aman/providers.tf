provider "aws" {
  region = var.region

  default_tags {
    tags = {
      kursus       = "komputasi-awan"
      nim          = var.nim
      kelompok     = var.kelompok
      modul        = "m05"
      stack        = "m05-aman"
      "managed-by" = "opentofu"
    }
  }
}
