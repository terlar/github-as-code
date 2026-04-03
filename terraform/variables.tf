# ---------------------------------------------------------------------------
# GitHub provider
# ---------------------------------------------------------------------------

variable "state_encryption_passphrase" {
  description = "Passphrase for OpenTofu state encryption (AES-GCM via PBKDF2). Supply via TF_VAR_state_encryption_passphrase / Actions secret TF_STATE_PASSPHRASE."
  type        = string
  sensitive   = true
}

variable "github_app_id" {
  description = "GitHub App ID used to authenticate the provider."
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID for the target account."
  type        = string
  sensitive   = true
}

variable "github_app_pem_key" {
  description = "GitHub App private key (PEM format)."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Repository defaults
# ---------------------------------------------------------------------------

variable "default_repo_visibility" {
  description = "Default visibility for managed repositories."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["private", "internal", "public"], var.default_repo_visibility)
    error_message = "Visibility must be one of: private, internal, public."
  }
}

variable "default_branch" {
  description = "Default branch name for all repositories."
  type        = string
  default     = "main"
}

# ---------------------------------------------------------------------------
# Branch protection defaults
# ---------------------------------------------------------------------------

variable "required_approving_review_count" {
  description = "Number of required approving reviews on the default branch."
  type        = number
  default     = 1
}

# ---------------------------------------------------------------------------
# Repositories
# ---------------------------------------------------------------------------

variable "repositories" {
  description = "Map of repository names to their configuration."
  type = map(object({
    description            = optional(string, "")
    visibility             = optional(string, null) # falls back to default_repo_visibility
    topics                 = optional(list(string), [])
    homepage_url           = optional(string, null)
    has_issues             = optional(bool, true)
    has_projects           = optional(bool, false)
    has_wiki               = optional(bool, false)
    has_discussions        = optional(bool, false)
    is_template            = optional(bool, false)
    archive_on_destroy     = optional(bool, true)
    archived               = optional(bool, false)
    auto_init              = optional(bool, false)
    gitignore_template     = optional(string, null)
    license_template       = optional(string, null)
    allow_merge_commit     = optional(bool, false)
    allow_squash_merge     = optional(bool, true)
    allow_rebase_merge     = optional(bool, false)
    allow_auto_merge       = optional(bool, false)
    delete_branch_on_merge = optional(bool, true)
    # Branch protection override — set to false to opt a repo out
    enable_branch_protection = optional(bool, true)
    # Required status checks for branch protection (empty = none required)
    required_status_checks = optional(list(string), [])
    # GitHub Pages configuration (null = disabled)
    pages = optional(object({
      build_type = optional(string, "legacy")
      source = object({
        branch = string
        path   = optional(string, "/")
      })
    }), null)
  }))
  default = {}
}
