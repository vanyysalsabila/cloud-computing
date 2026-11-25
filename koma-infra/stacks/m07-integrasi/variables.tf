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

# ---------------------------------------------------------------- nilai per lingkungan (env/*.tfvars)

variable "lingkungan" {
  type = string
  validation {
    condition     = contains(["dev", "prod"], var.lingkungan)
    error_message = "lingkungan hanya dev atau prod (G2)."
  }
}

variable "cost_center" {
  type        = string
  description = "Pusat biaya G1, berbentuk CC-123"
  validation {
    condition     = can(regex("^CC-[0-9]{3}$", var.cost_center))
    error_message = "cost_center berbentuk CC-123 (G4)."
  }
}

variable "data_class" {
  type        = string
  description = "Kelas data tertinggi yang boleh ada di lingkungan ini (A1, G4)"
  validation {
    condition     = contains(["publik", "internal", "rahasia"], var.data_class)
    error_message = "data_class hanya publik, internal, atau rahasia."
  }
  # TODO C.1  validasi kedua: data rahasia hanya boleh di lingkungan prod (G4)
}

variable "ukuran" {
  type    = string
  default = "kecil"
  validation {
    condition     = contains(["kecil", "sedang"], var.ukuran)
    error_message = "Ukuran hanya boleh kecil (128 MB) atau sedang (256 MB)."
  }
}

variable "retensi_hari" {
  type    = number
  default = 1
}

variable "dengan_dlq" {
  type    = bool
  default = false
}

variable "versi" {
  type    = string
  default = "1.0.0"
}

variable "anggaran_usd" {
  type        = number
  description = "Batas anggaran bulanan lingkungan ini (G3), USD"
  validation {
    condition     = var.anggaran_usd > 0 && var.anggaran_usd <= 10
    error_message = "anggaran_usd 0-10 (akun Free plan)."
  }
}

# ---------------------------------------------------------------- jejak penerap

variable "penerap" {
  type        = string
  default     = "lokal"
  description = "Diisi pipeline lewat TF_VAR_penerap=github-actions; apply dari laptop tetap lokal"
  validation {
    condition     = contains(["lokal", "github-actions"], var.penerap)
    error_message = "penerap hanya lokal atau github-actions."
  }
}

variable "run_id" {
  type        = string
  default     = "-"
  description = "Nomor run GitHub Actions (TF_VAR_run_id); '-' untuk apply lokal"
}
