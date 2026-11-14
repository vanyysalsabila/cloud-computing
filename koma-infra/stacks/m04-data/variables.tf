variable "nim" {
  type        = string
  description = "NIM mahasiswa"
  default     = "123450022"
}

variable "kelompok" {
  type        = string
  description = "Kode kelompok"
  default     = "k01"
}

variable "wilayah" {
  type        = string
  description = "Wilayah AWS"
  default     = "ap-southeast-2"
}

variable "versi" {
  type        = string
  default     = "4.0.0"
  description = "Versi aplikasi koma-api / iterasi data"
}

variable "ukuran_data_gib" {
  type        = number
  default     = 1
  description = "Ukuran volume EBS data dalam GiB"
  validation {
    condition     = var.ukuran_data_gib >= 1 && var.ukuran_data_gib <= 4
    error_message = "ukuran_data_gib harus antara 1 dan 4 GiB."
  }
}

variable "retensi_versi_hari" {
  type        = number
  default     = 30
  description = "Masa retensi versi lama objek dalam hari"
  validation {
    condition     = var.retensi_versi_hari >= 1 && var.retensi_versi_hari <= 365
    error_message = "retensi_versi_hari harus antara 1 dan 365 hari."
  }
}
