import {
  for_each = var.repositories
  id       = each.key
  to       = github_repository.managed[each.key]
}
