output "repository_urls" {
  description = "HTTP clone URLs of all managed repositories."
  value       = { for name, repo in github_repository.managed : name => repo.http_clone_url }
}

output "repository_ssh_urls" {
  description = "SSH clone URLs of all managed repositories."
  value       = { for name, repo in github_repository.managed : name => repo.ssh_clone_url }
}
