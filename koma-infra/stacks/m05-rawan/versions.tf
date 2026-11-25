# PERINGATAN: stack ini SENGAJA rawan (warisan kontraktor, Babak 5). Hanya untuk di-plan dan
# diaudit. JANGAN `tofu apply`. Tanpa backend: plan tidak menulis state.
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
