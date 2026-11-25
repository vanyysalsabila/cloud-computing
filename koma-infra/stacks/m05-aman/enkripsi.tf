terraform {
  encryption {
    key_provider "pbkdf2" "utama" {
      passphrase = var.kunci_state
    }

    method "aes_gcm" "utama" {
      keys = key_provider.pbkdf2.utama
    }

    state {
      method   = method.aes_gcm.utama
      enforced = true
    }

    plan {
      method   = method.aes_gcm.utama
      enforced = true
    }
  }
}
