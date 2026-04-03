{ inputs, ... }:

{
  imports = [
    inputs.dev-flake.flakeModule
    inputs.first-ci-kit.flakeModules.default
    inputs.first-ci-kit.flakeModules.git-hooks
    ./ci.nix
  ];

  systems = [ "x86_64-linux" ];

  dev.name = "github-as-code";
  debug = true;

  perSystem =
    { config, pkgs, ... }:
    {
      formatter = config.treefmt.programs.nixfmt.package;

      treefmt = {
        programs.nixfmt.enable = true;
      };

      pre-commit.check.enable = false;
      pre-commit.settings.hooks = {
        # PR pipeline → on-pull-request.yml
        first-ci-kit-gen-github-actions = {
          enable = true;
          settings.pipeline = "pr";
          settings.outputPath = ".github/workflows/on-pull-request.yml";
          files = "^dev/ci\\.nix$";
        };

        # Push pipeline → on-main-push.yml (custom hook, same mechanism)
        first-ci-kit-gen-github-actions-push = {
          enable = true;
          package = pkgs.writeShellApplication {
            name = "generate-github-actions-push";
            runtimeInputs = [ pkgs.yq-go ];
            text = ''
              out="$(nix build --extra-experimental-features 'nix-command flakes' \
                --print-out-paths \
                .#ci-pipeline-github-actions-push
              )"
              mkdir -p .github/workflows
              yq --prettyPrint --output-format yaml "$out" > .github/workflows/on-main-push.yml
            '';
          };
          entry = "${config.pre-commit.settings.hooks.first-ci-kit-gen-github-actions-push.package}/bin/generate-github-actions-push";
          files = "^dev/ci\\.nix$";
          pass_filenames = false;
        };
      };
    };
}
