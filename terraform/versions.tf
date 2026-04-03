terraform {
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # ---------------------------------------------------------------------------
  # State encryption — AES-GCM with PBKDF2 key derivation.
  #
  # The passphrase is supplied via TF_VAR_state_encryption_passphrase (Actions
  # secret TF_STATE_PASSPHRASE). The state file committed to terlar/terraform-state
  # is encrypted before it ever leaves the OpenTofu process.
  #
  # IMPORTANT: keep the passphrase backed up. Loss of it = unrecoverable state.
  #
  # To migrate an existing unencrypted state file, temporarily add:
  #   method "unencrypted" "migrate" {}
  #   fallback { method = method.unencrypted.migrate }
  # inside the state {} block, run tofu apply once, then remove the fallback.
  # ---------------------------------------------------------------------------
  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
