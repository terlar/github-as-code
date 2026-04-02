{
  description = "github-as-code";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    dev-flake = {
      url = "github:terlar/dev-flake";
      inputs.flake-parts.follows = "flake-parts";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        inputs.flake-parts.flakeModules.partitions
        inputs.dev-flake.flakeModule
      ];

      partitionedAttrs = {
        checks = "dev";
        devShells = "dev";
        packages = "dev";
        legacyPackages = "dev";
        debug = "dev";
      };

      partitions.dev = {
        extraInputsFlake = ./dev;
        module.imports = [ ./dev/flake-module.nix ];
      };

      perSystem =
        { config, pkgs, ... }:
        {
          packages.tofu = pkgs.writeShellApplication {
            name = "tofu";
            runtimeInputs = with pkgs; [
              terraform-backend-git
              opentofu
            ];
            text = ''
              case "''${1:-}" in
                init|plan|apply|destroy|import|state|output|refresh)
                  exec terraform-backend-git \
                    git \
                    --repository https://github.com/terlar/terraform-state \
                    --ref main \
                    --state github-as-code.tfstate \
                    terraform \
                    --tf tofu \
                    "$@"
                  ;;
                *)
                  exec tofu "$@"
                  ;;
              esac
            '';
          };

          checks = config.packages;
        };
    };
}
