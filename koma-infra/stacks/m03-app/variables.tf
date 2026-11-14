variable "nim" {
  type        = string
  description = "NIM mahasiswa"
}

variable "kelompok" {
  type        = string
  description = "ID kelompok (misal k01)"
}

variable "region" {
  type        = string
  default     = "ap-southeast-2"
  description = "Region AWS"
}

variable "cidr_saya" {
  type        = string
  description = "IP publik komputer mahasiswa dalam format CIDR /32"
  validation {
    condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/32$", var.cidr_saya))
    error_message = "cidr_saya harus berformat IP publik dengan prefix /32."
  }
}

variable "jumlah_web" {
  type        = number
  default     = 2
  description = "Jumlah server web"
  validation {
    condition     = var.jumlah_web >= 1 && var.jumlah_web <= 4
    error_message = "jumlah_web harus antara 1 dan 4."
  }
}

variable "versi" {
  type        = string
  default     = "3.0.0"
  description = "Versi aplikasi koma-api"
}
