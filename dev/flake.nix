{
  description = "Development dependencies for github-as-code";

  inputs = {
    dev-flake.url = "github:terlar/dev-flake";
    first-ci-kit = {
      url = "github:terlar/first-ci-kit";
      inputs.flake-parts.follows = "dev-flake/flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = _: { };
}
