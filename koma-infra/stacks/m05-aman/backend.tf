# State di bucket m00-state (Modul 04), key terpisah dari stack lain:
#   tofu init -backend-config=backend.hcl
# Isinya dienkripsi OpenTofu sebelum dikirim ke S3 (lihat enkripsi.tf).
terraform {
  backend "s3" {}
}
