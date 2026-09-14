{
  description = "Development dependencies for github-as-code";

  inputs = {
    dev-flake.url = "github:terlar/dev-flake";
    first-ci-kit = {
      url = "github:terlar/first-ci-kit";
      inputs.flake-parts.follows = "dev-flake/flake-parts";
    };
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  };

  outputs = _: { };
}
