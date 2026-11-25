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

variable "cidr_saya" {
  type        = string
  description = "IP publik komputer praktikan sebagai /32 (keluaran `koma ip`, sama dengan saat legacy dibuat)"
  validation {
    condition     = can(cidrhost(var.cidr_saya, 0)) && endswith(var.cidr_saya, "/32")
    error_message = "Isi dengan satu alamat IPv4 berakhiran /32, mis. 36.70.1.2/32."
  }
}

variable "pertahankan_legacy" {
  type        = bool
  default     = true
  description = "false = contract: server legacy dan target group biru dibongkar"
}

variable "aktif" {
  type        = string
  default     = "biru"
  description = "Target group yang menerima lalu lintas ALB: biru (legacy) atau hijau (versi baru)"
  validation {
    condition     = contains(["biru", "hijau"], var.aktif)
    error_message = "aktif harus biru atau hijau."
  }
}

variable "versi_hijau" {
  type        = string
  default     = "6.0.0"
  description = "Versi koma-api di server hijau"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.versi_hijau))
    error_message = "Versi berbentuk MAYOR.MINOR.PATCH."
  }
}

variable "ambang_latensi_detik" {
  type        = number
  default     = 0.3
  description = "Alarm menyala bila p95 waktu respons target melewati ambang ini (detik)"
  validation {
    condition     = var.ambang_latensi_detik > 0 && var.ambang_latensi_detik <= 5
    error_message = "Ambang latensi 0-5 detik."
  }
}
