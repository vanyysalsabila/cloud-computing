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

variable "cidr_vpc" {
  type        = string
  default     = "10.1.0.0/16"
  description = "CIDR block VPC"
  validation {
    condition     = can(regex("^10\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/16$", var.cidr_vpc))
    error_message = "CIDR VPC harus tepat /16 di 10.0.0.0/8."
  }
}
