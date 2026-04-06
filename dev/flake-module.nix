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
    { config, ... }:
    {
      formatter = config.treefmt.programs.nixfmt.package;

      treefmt = {
        programs.nixfmt.enable = true;
      };

      pre-commit.check.enable = false;
      pre-commit.settings.hooks = {
        first-ci-kit-gen-github-actions = {
          enable = true;
          settings.pipelines = {
            pr = ".github/workflows/on-pull-request.yml";
            push = ".github/workflows/on-main-push.yml";
          };
          files = "^dev/ci\\.nix$";
        };
      };
    };
}
