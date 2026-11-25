# Identitas pipeline GitHub Actions (Modul 07, dijalankan SEKALI dari laptop dan TIDAK di-destroy
# selama kursus; Modul 08 memakainya lagi). State lokal, seperti m00-pagar.
#
# Tanpa kunci akses: GitHub menerbitkan token OIDC untuk setiap run, AWS memeriksa tanda tangan
# dan isi token (aud, sub), lalu memberi kredensial sementara role koma-<nim>-pipeline selama
# paling lama satu jam. Tidak ada rahasia AWS yang disimpan di GitHub.
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "nim" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{8,10}$", var.nim))
    error_message = "NIM harus 8-10 digit angka."
  }
}

variable "kelompok" {
  type = string
  validation {
    condition     = can(regex("^k0[0-5]$", var.kelompok))
    error_message = "Kelompok harus k01-k05 (k00 untuk contoh dosen)."
  }
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "github_repo" {
  type        = string
  description = "Repo koma-infra Anda di GitHub, berbentuk pemilik/nama (mis. rinaw/koma-infra)"
  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repo))
    error_message = "github_repo berbentuk pemilik/nama, tanpa https://github.com/ dan tanpa *."
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      kursus       = "komputasi-awan"
      nim          = var.nim
      kelompok     = var.kelompok
      modul        = "m00"
      stack        = "m00-pipeline"
      "managed-by" = "opentofu"
    }
  }
}

data "aws_caller_identity" "saya" {}

locals {
  akun   = data.aws_caller_identity.saya.account_id
  awalan = "koma-${var.nim}-m07"
}

# TODO E.1  aws_iam_openid_connect_provider.github (url token.actions.githubusercontent.com,
#           client_id_list sts.amazonaws.com)
# TODO E.1  aws_iam_role.pipeline ("koma-${var.nim}-pipeline", sesi maks. 3600): trust Federated ke provider,
#           sts:AssumeRoleWithWebIdentity, aud = sts.amazonaws.com, sub hanya
#           repo:<github_repo>:ref:refs/heads/main dan repo:<github_repo>:pull_request
# TODO E.1  aws_iam_role_policy.pipeline "koma-pipeline-m07": tujuh pernyataan di naskah (StateM07,
#           DaftarState, JalurM07, RoleFungsi, SerahkanRoleKeLambda, PemetaanAntrean,
#           TagPemetaanAntrean, BacaTanpaBatasResource)
# TODO E.1  output role_arn dan oidc_provider_arn
