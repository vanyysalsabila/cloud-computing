provider "aws" {
  region = var.region
  default_tags {
    tags = {
      kursus       = "komputasi-awan"
      nim          = var.nim
      kelompok     = var.kelompok
      modul        = "m00"
      stack        = "m00-verifier"
      "managed-by" = "opentofu"
    }
  }
}
