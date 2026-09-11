# ---------------------------------------------------------------------------
# Repositories
#
# Add repos to the `repositories` variable in terraform.tfvars.
#
# Minimal example:
#
#   repositories = {
#     my-repo = {
#       description = "My repo"
#       topics      = ["nix"]
#     }
#   }
#
# Full example with all overrides:
#
#   repositories = {
#     my-repo = {
#       description              = "My repo"
#       visibility               = "public"
#       topics                   = ["nix"]
#       homepage_url             = "https://example.com"
#       has_issues               = true
#       has_projects             = false
#       has_wiki                 = false
#       allow_squash_merge       = true
#       allow_merge_commit       = false
#       allow_rebase_merge       = false
#       delete_branch_on_merge   = true
#       enable_branch_protection = true
#       required_status_checks   = ["CI / build"]
#       enable_secret_scanning   = true
#       vulnerability_alerts     = true
#     }
#   }
# ---------------------------------------------------------------------------

resource "github_repository" "managed" {
  for_each = var.repositories

  name        = each.key
  description = each.value.description
  visibility  = coalesce(each.value.visibility, var.default_repo_visibility)

  # Features
  has_issues      = each.value.has_issues
  has_projects    = each.value.has_projects
  has_wiki        = each.value.has_wiki
  has_discussions = each.value.has_discussions
  is_template     = each.value.is_template
  homepage_url    = each.value.homepage_url

  # Topics
  topics = each.value.topics

  # Merge strategy — squash only by default
  allow_merge_commit     = each.value.allow_merge_commit
  allow_squash_merge     = each.value.allow_squash_merge
  allow_rebase_merge     = each.value.allow_rebase_merge
  allow_auto_merge       = each.value.allow_auto_merge
  delete_branch_on_merge = each.value.delete_branch_on_merge

  # Initialisation (only relevant for brand-new repos)
  auto_init          = each.value.auto_init
  gitignore_template = each.value.gitignore_template
  license_template   = each.value.license_template

  # Safety: archive instead of destroy
  archive_on_destroy = each.value.archive_on_destroy
  archived           = each.value.archived

  # Security: Dependabot alerts and secret scanning (archived repos untouched)
  vulnerability_alerts = each.value.archived ? null : each.value.vulnerability_alerts

  dynamic "security_and_analysis" {
    for_each = each.value.enable_secret_scanning && !each.value.archived ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }

  # GitHub Pages
  dynamic "pages" {
    for_each = each.value.pages != null ? [each.value.pages] : []
    content {
      build_type = pages.value.build_type
      dynamic "source" {
        # Only "legacy" builds use a source branch; "workflow" builds are
        # deployed from GitHub Actions artifacts (see the provider schema).
        for_each = pages.value.build_type == "legacy" ? [pages.value.source] : []
        content {
          branch = source.value.branch
          path   = source.value.path
        }
      }
    }
  }

  lifecycle {
    # Prevent accidental name changes — rename manually if needed
    ignore_changes = [name]
  }
}
