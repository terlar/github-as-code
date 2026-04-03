import {
  for_each = var.repositories
  id       = each.key
  to       = github_repository.managed[each.key]
}

# Existing branch protection rules to import
import {
  id = "nix-config:main"
  to = github_branch_protection.managed["nix-config"]
}

import {
  id = "emacs-config:main"
  to = github_branch_protection.managed["emacs-config"]
}
