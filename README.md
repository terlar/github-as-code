# GitHub as Code

Manage your GitHub repositories as code using OpenTofu and the GitHub provider.

## Overview

This repository contains OpenTofu configuration that manages GitHub repositories for the `terlar` user. It uses:

- [OpenTofu](https://opentofu.org/) for infrastructure as code
- [terraform-backend-git](https://github.com/plumber-cd/terraform-backend-git) for state storage
- [GitHub provider](https://registry.terraform.io/providers/integrations/github/latest) for repository management
- [first-ci-kit](https://github.com/terlar/first-ci-kit) for CI/CD pipeline generation

## State Management

State is stored in a Git repository (`terlar/terraform-state`) using the terraform-backend-git backend with AES256 encryption.

### Required Secrets

Add these secrets to your GitHub repository:

- `TF_STATE_PASSPHRASE` - Passphrase used for encrypting the terraform state

## Quick Start

### Setup

```bash
nix develop
direnv allow
```

### Commands

```bash
nix run . -- import   # Import existing repositories
nix run . -- plan     # Plan changes
nix run . -- apply   # Apply changes
```

## Repository Management

This configuration manages the following repositories (all public, non-fork):

archbox, base16-vim-powerline, box, curio, dev-flake, docker-dev-tools, docker-nix, docker-skype-pulseaudio, docker-spotify-pulseaudio, dotfiles, emacs-config, emacs-find-project, evil-stateful, exercism-workspace, first-ci-kit, first-ci-kit-demo, fish-farm, fish-plug, fish-tank, formatter, formatter-date, formatter-number, fry, indent-info.el, menu, mux, nix-config, nix-service-monorepo, nix-terraform, org-mode, pkgbuilds, pre-commit-treefmt-bug, resume, sam-playground, terlar.github.io, vim-ref-fish, vimfiles, zshfiles

## Branch Protection

All repositories have the following branch protection rules on `main`:

- Admins enforced
- 1 required approval
- Required status check: `Terraform` (strict mode)
- Force pushes blocked
- Signed commits required
