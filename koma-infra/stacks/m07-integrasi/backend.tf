# Satu folder, dua state: pilih lingkungan saat init.
#   tofu init -reconfigure -backend-config=env/dev.backend.hcl
#   tofu init -reconfigure -backend-config=env/prod.backend.hcl
terraform {
  backend "s3" {}
}
