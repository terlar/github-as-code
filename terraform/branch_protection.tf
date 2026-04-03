# ---------------------------------------------------------------------------
# Branch protection rules
#
# A rule is created for every repository that has `enable_branch_protection`
# set to true (the default). The rule targets the default branch (var.default_branch).
#
# Requirements:
#   - 1 approving review (var.required_approving_review_count)
#   - Status checks listed in `required_status_checks` for that repo
#   - Dismiss stale reviews on new pushes
#   - Require branches to be up-to-date before merging
#   - Signed commits required
#   - Restrict force-pushes and deletions
# ---------------------------------------------------------------------------

locals {
  protected_repos = {
    for name, cfg in var.repositories : name => cfg
    if cfg.enable_branch_protection && !cfg.archived
  }
}

resource "github_branch_protection" "managed" {
  for_each = local.protected_repos

  repository_id = each.key
  pattern       = var.default_branch

  # Enforce on administrators as well
  enforce_admins = true

  # Require signed commits
  require_signed_commits = true

  # Prevent force-pushes and deletions
  allows_force_pushes = false
  allows_deletions    = false

  required_pull_request_reviews {
    required_approving_review_count = var.required_approving_review_count
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
  }

  dynamic "required_status_checks" {
    for_each = length(each.value.required_status_checks) > 0 ? [1] : []
    content {
      strict   = true
      contexts = each.value.required_status_checks
    }
  }
}
