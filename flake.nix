{
  description = "nix-rust-template";

  nixConfig.bash-prompt = "[nix]λ ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, naersk, nixpkgs, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          rust-overlay.overlay
          naersk.overlay
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rust = pkgs.rust-bin.stable.latest.default;
        naersk-lib = pkgs.naersk.override {
          cargo = pkgs.rust-bin.nightly.latest.cargo;
          rustc = rust;
        };
        rust-dev = rust.override {
          extensions = [
            "clippy-preview"
            "rust-src"
            "rustc-dev"
            "rustfmt-preview"
          ];
        };
      in rec {
        # `nix build`
        packages.nix-rust-template = naersk-lib.buildPackage {
          pname = "nix-rust-template";
          root = ./.;
        };
        defaultPackage = packages.nix-rust-template;

        # `nix run`
        apps.nix-rust-template = flake-utils.lib.mkApp {
          drv = packages.nix-rust-template;
        };
        defaultApp = apps.nix-rust-template;

        # `nix develop`
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.cargo-edit
            pkgs.cargo-watch
            pkgs.rust-analyzer
          ];
          nativeBuildInputs = [ rust-dev ];
        };
      }
    );
}
