variable "nim" {
  type        = string
  description = "NIM praktikan; dipakai di tag dan nama resource"
  validation {
    condition     = can(regex("^[0-9]{8,10}$", var.nim))
    error_message = "NIM harus 8-10 digit angka."
  }
}

variable "kelompok" {
  type        = string
  description = "ID kelompok kasus (k01-k05; k00 contoh dosen)"
  validation {
    condition     = can(regex("^k0[0-5]$", var.kelompok))
    error_message = "Kelompok harus k01-k05 (k00 untuk contoh dosen)."
  }
}

variable "region" {
  type        = string
  default     = "ap-southeast-2"
  description = "Region proyek AWS (Indonesia: ap-southeast-2)"
}

variable "cidr_saya" {
  type        = string
  description = "IP publik Anda dalam format CIDR /32 (dapatkan dari perintah `koma ip`)"
  validation {
    condition     = can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}/32$", var.cidr_saya))
    error_message = "cidr_saya harus berupa IP v4 berprefix /32 (mis. 103.xxx.xxx.xxx/32)."
  }
}

variable "versi" {
  type        = string
  default     = "2.0.0"
  description = "Versi aplikasi koma-api yang dipanggang ke AMI (nilai bawaan 2.0.0 untuk uji statis)"
  validation {
    condition     = can(regex("^v?[0-9]+(\\.[0-9]+)*$", var.versi))
    error_message = "Versi harus berformat versi (mis. 2.0.0, v1, v2)."
  }
}

variable "jumlah_server_goreng" {
  type        = number
  default     = 0
  description = "Jumlah server goreng untuk pengujian perbandingan waktu siap"
}

variable "buat_image" {
  type        = bool
  default     = true
  description = "Apakah membuat AMI dari instance pembangun"
}

variable "jalankan_api" {
  type        = bool
  default     = true
  description = "Apakah meluncurkan instance API dari AMI hasil panggangan"
}
