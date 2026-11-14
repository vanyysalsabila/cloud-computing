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
