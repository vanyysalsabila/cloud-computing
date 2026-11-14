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
