{ lib, ... }:

let
  # GitHub App credentials + state passphrase, sourced from Actions secrets/vars
  tofuEnv = {
    TF_VAR_github_app_id = "\${{ vars.GH_APP_ID }}";
    TF_VAR_github_app_installation_id = "\${{ vars.GH_APP_INSTALLATION_ID }}";
    TF_VAR_github_app_pem_key = "\${{ secrets.GH_APP_PEM_KEY }}";
    TF_VAR_state_encryption_passphrase = "\${{ secrets.TF_STATE_PASSPHRASE }}";
  };

  # git credentials for terraform-backend-git — only valid at step level
  # (steps.app-token is unavailable in job-level env blocks)
  gitEnv = {
    GIT_USERNAME = "x-access-token";
    GIT_PASSWORD = "\${{ steps.app-token.outputs.token }}";
  };

  jobSets = {
    nix = {
      tags = [ "nix" ];
      jobDefaults.github-actions = {
        steps = [ { uses = "canidae-solutions/lix-quick-install-action@v4"; } ];
      };
    };

    terraform = {
      tags = [ "terraform" ];
      jobDefaults.github-actions = {
        steps = [
          { uses = "canidae-solutions/lix-quick-install-action@v4"; }
          {
            name = "Install tofu";
            run = "nix profile install .#tofu";
          }
          # Short-lived GitHub App token for terraform-backend-git
          {
            name = "Generate GitHub App token";
            id = "app-token";
            uses = "actions/create-github-app-token@v3";
            "with" = {
              client-id = "\${{ vars.GH_CLIENT_ID }}";
              private-key = "\${{ secrets.GH_APP_PEM_KEY }}";
              repositories = "terraform-state";
            };
          }
        ];
      };
    };
  };
in

{
  first-ci-kit.pipelines = {
    # -------------------------------------------------------------------------
    # PR pipeline: run nix flake check + tofu plan, post plan as PR comment
    # -------------------------------------------------------------------------
    pr = {
      pipeline = {
        github-actions = {
          defaultRunsOn = "ubuntu-latest";
          settings = {
            name = "Pull Request";
            on.pull_request.branches = [ "main" ];
            on.pull_request.paths = [
              "terraform/**"
              "flake.nix"
              "flake.lock"
              ".github/workflows/**"
            ];
            concurrency = {
              group = "pull-request-\${{ github.event.pull_request.number }}";
              cancel-in-progress = true;
            };
            permissions = {
              contents = "read";
              pull-requests = "write";
            };
          };
        };

        process-compose.cli.environment.PC_DISABLE_TUI = true;
      };

      inherit jobSets;

      jobs = {
        checks = {
          tags = [ "nix" ];
          commands = [ "nix flake check --print-build-logs" ];
        };

        plan = {
          tags = [ "terraform" ];
          github-actions = {
            env = tofuEnv;
            defaults.run.working-directory = "terraform";
            steps = lib.mkAfter [
              {
                name = "tofu init";
                run = "tofu init -input=false";
                env = gitEnv;
              }
              {
                name = "tofu validate";
                run = "tofu validate -no-color";
              }
              {
                name = "tofu plan";
                run = "set -o pipefail; tofu plan -no-color -input=false 2>&1 | tee plan.txt";
                env = gitEnv;
              }
              {
                name = "Post plan as PR comment";
                uses = "actions/github-script@v8";
                "if" = "always()";
                "with" = {
                  working-directory = "terraform";
                  script = ''
                    const fs = require('fs');
                    let plan;
                    try {
                      plan = fs.readFileSync('plan.txt', 'utf8');
                    } catch (e) {
                      plan = 'Plan output not available.';
                    }
                    const maxLen = 65000;
                    const truncated = plan.length > maxLen
                      ? plan.slice(0, maxLen) + '\n\n... (truncated, see job logs for full output)'
                      : plan;
                    const body = `## OpenTofu Plan\n\n<details><summary>Show Plan</summary>\n\n\`\`\`hcl\n''${truncated}\n\`\`\`\n\n</details>`;
                    const { data: comments } = await github.rest.issues.listComments({
                      owner: context.repo.owner,
                      repo: context.repo.repo,
                      issue_number: context.issue.number,
                    });
                    for (const comment of comments) {
                      if (comment.user.type === 'Bot' && comment.body.startsWith('## OpenTofu Plan')) {
                        await github.rest.issues.deleteComment({
                          owner: context.repo.owner,
                          repo: context.repo.repo,
                          comment_id: comment.id,
                        });
                      }
                    }
                    await github.rest.issues.createComment({
                      owner: context.repo.owner,
                      repo: context.repo.repo,
                      issue_number: context.issue.number,
                      body,
                    });
                  '';
                };
              }
            ];
          };
        };
      };
    };

    # -------------------------------------------------------------------------
    # Push pipeline: run tofu plan then apply on push to main
    # -------------------------------------------------------------------------
    push = {
      pipeline = {
        github-actions = {
          defaultRunsOn = "ubuntu-latest";
          settings = {
            name = "Push";
            on.push.branches = [ "main" ];
            on.push.paths = [
              "terraform/**"
              "flake.nix"
              "flake.lock"
              ".github/workflows/**"
            ];
            concurrency = {
              group = "main-push";
              cancel-in-progress = false;
            };
            permissions.contents = "read";
          };
        };

        process-compose.cli.environment.PC_DISABLE_TUI = true;
      };

      inherit jobSets;

      jobs = {
        plan = {
          tags = [ "terraform" ];
          github-actions = {
            env = tofuEnv;
            defaults.run.working-directory = "terraform";
            steps = lib.mkAfter [
              {
                name = "tofu init";
                run = "tofu init -input=false";
                env = gitEnv;
              }
              {
                name = "tofu validate";
                run = "tofu validate -no-color";
              }
              {
                name = "tofu plan";
                run = "tofu plan -no-color -input=false -out=tfplan";
                env = gitEnv;
              }
              {
                name = "Upload plan";
                uses = "actions/upload-artifact@v4";
                "with" = {
                  name = "tfplan";
                  path = "terraform/tfplan";
                };
              }
            ];
          };
        };

        apply = {
          tags = [ "terraform" ];
          needs = [ { job = "plan"; } ];
          github-actions = {
            env = tofuEnv;
            environment = "production";
            defaults.run.working-directory = "terraform";
            steps = lib.mkAfter [
              {
                name = "Download plan";
                uses = "actions/download-artifact@v4";
                "with" = {
                  name = "tfplan";
                  path = "terraform";
                };
              }
              {
                name = "tofu init";
                run = "tofu init -input=false";
                env = gitEnv;
              }
              {
                name = "tofu apply";
                run = "tofu apply -input=false tfplan";
                env = gitEnv;
              }
            ];
          };
        };
      };
    };
  };
}
