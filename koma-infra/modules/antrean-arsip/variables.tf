# Antarmuka modul antrean-arsip: enam masukan, tanpa satu pun nama resource AWS.
# Pemanggil memilih "apa" (lingkungan, ukuran, retensi, DLQ); modul memutuskan "bagaimana".

variable "awalan" {
  type        = string
  description = "Awalan nama semua resource, mis. koma-121450001-m07-dev"
  validation {
    condition     = can(regex("^koma-[0-9]{8,10}-m0[7-8]-(dev|prod)$", var.awalan))
    error_message = "awalan berbentuk koma-<nim>-m07-<dev|prod>."
  }
}

variable "lingkungan" {
  type = string
  validation {
    condition     = contains(["dev", "prod"], var.lingkungan)
    error_message = "lingkungan hanya dev atau prod."
  }
}

variable "ukuran" {
  type        = string
  default     = "kecil"
  description = "Preset memori fungsi pengarsip: kecil (128 MB) atau sedang (256 MB)"
  validation {
    condition     = contains(["kecil", "sedang"], var.ukuran)
    error_message = "Ukuran hanya boleh kecil (128 MB) atau sedang (256 MB)."
  }
}

variable "retensi_hari" {
  type        = number
  default     = 1
  description = "Objek arsip dihapus otomatis setelah sekian hari (lab: 1-7 hari)"
  validation {
    condition     = var.retensi_hari >= 1 && var.retensi_hari <= 7 && floor(var.retensi_hari) == var.retensi_hari
    error_message = "retensi_hari bilangan bulat 1-7 (bucket lab, bukan arsip sungguhan)."
  }
}

variable "dengan_dlq" {
  type        = bool
  default     = false
  description = "true = pesan yang gagal diproses 3 kali dipindah ke antrean -gagal (dead-letter queue)"
}

variable "versi" {
  type        = string
  default     = "1.0.0"
  description = "Versi pengarsip; ikut tertulis di setiap objek arsip"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.versi))
    error_message = "Versi berbentuk MAYOR.MINOR.PATCH."
  }
}
