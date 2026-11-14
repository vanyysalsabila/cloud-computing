provider "aws" {
  region = var.region
  default_tags {
    tags = {
      kursus       = "komputasi-awan"
      nim          = var.nim
      kelompok     = var.kelompok
      modul        = "m03"
      stack        = "m03-app"
      "managed-by" = "opentofu"
    }
  }
}
