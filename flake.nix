{
  description = "A reasonable way to start developing a reproducible Rust project";

  nixConfig.bash-prompt = "[nix]λ ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Builds cargo projects with dependency caching and cargo-based checks.
    crane.url = "github:ipetkov/crane";

    # Rust toolchains as pure, binary-cached Nix packages.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      rust-overlay,
    }:
    let
      inherit (nixpkgs) lib;

      # Intel macOS is not here: nixpkgs unstable dropped x86_64-darwin in
      # 26.11. Pin `nixpkgs` to "github:NixOS/nixpkgs/nixpkgs-26.05-darwin"
      # and add it back if you still need it.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Everything Rust-related is set up once per system here, so the outputs
      # below can stay short and declarative.
      mkContext =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };

          # One toolchain definition shared by rustup and Nix users. crane takes
          # a function so it can also build the toolchain for cross targets.
          mkToolchain = p: p.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          toolchain = mkToolchain pkgs;

          craneLib = (crane.mkLib pkgs).overrideToolchain mkToolchain;

          # Only cargo-relevant files, so unrelated edits do not trigger rebuilds.
          src = craneLib.cleanCargoSource ./.;

          crate = craneLib.crateNameFromCargoToml { inherit src; };

          commonArgs = {
            inherit src;
            strictDeps = true;
            # Native libraries your crate links against go here, e.g.
            #   buildInputs = [ pkgs.openssl ];
            #   nativeBuildInputs = [ pkgs.pkg-config ];
          };

          # Build only the dependencies so they can be cached (locally and in
          # CI) independently of the crate's own source.
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;

          package = craneLib.buildPackage (
            commonArgs
            // {
              inherit cargoArtifacts;
              # Tests run in their own check below; no need to run them twice.
              doCheck = false;
              meta.mainProgram = crate.pname;
            }
          );
        in
        {
          inherit
            pkgs
            toolchain
            craneLib
            src
            crate
            commonArgs
            cargoArtifacts
            package
            ;
        };

      contexts = lib.genAttrs systems mkContext;
      forEachSystem = f: lib.mapAttrs (_: f) contexts;
    in
    {
      # `nix build`
      packages = forEachSystem (
        {
          pkgs,
          package,
          crate,
          ...
        }:
        {
          default = package;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          # `nix build .#docker && docker load < result`
          # A minimal production image holding only the binary and its runtime
          # closure. Linux only, because that is what containers run.
          docker = pkgs.dockerTools.buildLayeredImage {
            name = crate.pname;
            tag = crate.version;
            config.Cmd = [ (lib.getExe package) ];
          };
        }
      );

      # `nix flake check`
      checks = forEachSystem (
        {
          craneLib,
          src,
          commonArgs,
          cargoArtifacts,
          package,
          ...
        }:
        {
          build = package;

          clippy = craneLib.cargoClippy (
            commonArgs
            // {
              inherit cargoArtifacts;
              cargoClippyExtraArgs = "--all-targets -- --deny warnings";
            }
          );

          doc = craneLib.cargoDoc (
            commonArgs
            // {
              inherit cargoArtifacts;
              env.RUSTDOCFLAGS = "--deny warnings";
            }
          );

          fmt = craneLib.cargoFmt { inherit src; };

          test = craneLib.cargoTest (commonArgs // { inherit cargoArtifacts; });
        }
      );

      # `nix run .#watch`: rebuild and rerun on every source change.
      apps = forEachSystem (
        { pkgs, toolchain, ... }:
        {
          watch = {
            type = "app";
            meta.description = "Rebuild and rerun the crate whenever a source file changes";
            program = lib.getExe (
              pkgs.writeShellApplication {
                name = "watch";
                runtimeInputs = [
                  pkgs.bacon
                  pkgs.stdenv.cc
                  toolchain
                ];
                # `bacon run-long` is the job to use for servers and other
                # long-running programs.
                text = ''bacon run "$@"'';
              }
            );
          };
        }
      );

      # `nix develop`, or automatically via direnv (see .envrc)
      devShells = forEachSystem (
        { pkgs, craneLib, ... }:
        {
          default = craneLib.devShell {
            # Everything the checks need is available interactively too.
            checks = self.checks.${pkgs.stdenv.hostPlatform.system};
            packages = [ pkgs.bacon ];
          };
        }
      );

      # `nix fmt`: formats Nix files with nixfmt and Rust files with rustfmt.
      formatter = forEachSystem (
        { pkgs, toolchain, ... }:
        pkgs.nixfmt-tree.override {
          runtimeInputs = [ toolchain ];
          settings.formatter.rustfmt = {
            command = "rustfmt";
            options = [
              "--edition"
              "2024"
            ];
            includes = [ "*.rs" ];
          };
        }
      );

      # `nix flake init -t github:rpearce/nix-rust-template`
      templates.default = {
        path = ./.;
        description = "A reproducible Rust project: crane, rust-overlay, bacon and CI";
        welcomeText = ''
          # nix-rust-template

          Next steps:

          1. Rename the crate: `name`, `description` and `repository` in Cargo.toml
          2. Update README.md (its badge and `nix flake init` line point at the
             template), and remove or update .github/FUNDING.yml and LICENSE
          3. `nix flake check` to build and run every check
          4. `nix develop` (or `direnv allow`) for a shell with the toolchain
        '';
      };
    };
}
