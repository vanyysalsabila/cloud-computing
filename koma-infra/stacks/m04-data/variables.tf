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

variable "iterasi" {
  type        = string
  description = "Penanda iterasi untuk versi state"
  default     = "1"
}
