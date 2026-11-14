provider "aws" {
  region = var.wilayah

  default_tags {
    tags = {
      nim        = var.nim
      kelompok   = var.kelompok
      managed-by = "opentofu"
    }
  }
}
