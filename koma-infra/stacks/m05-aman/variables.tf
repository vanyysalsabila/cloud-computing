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

variable "versi" {
  type        = string
  default     = "5.0.0"
  description = "Versi koma-api"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.versi))
    error_message = "Versi berbentuk MAYOR.MINOR.PATCH."
  }
}

variable "cidr_saya" {
  type        = string
  description = "IP publik komputer praktikan sebagai /32 (keluaran `koma ip`)"
  validation {
    condition     = can(cidrhost(var.cidr_saya, 0)) && endswith(var.cidr_saya, "/32")
    error_message = "Isi dengan satu alamat IPv4 berakhiran /32, mis. 36.70.1.2/32."
  }
}

variable "putaran_rahasia" {
  type        = number
  default     = 1
  description = "Naikkan satu angka untuk merotasi password database"
  validation {
    condition     = var.putaran_rahasia >= 1 && var.putaran_rahasia <= 20
    error_message = "Putaran rahasia 1-20."
  }
}

# TODO D.1  variable "kunci_state": string, sensitive, tanpa nilai bawaan, validasi panjang >= 16.
