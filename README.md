# nix-rust-template

A reasonable way to start developing a reproducible
[Rust](https://www.rust-lang.org) project, powered by [Nix](https://nixos.org).

[![CI](https://github.com/rpearce/nix-rust-template/actions/workflows/ci.yml/badge.svg)](https://github.com/rpearce/nix-rust-template/actions/workflows/ci.yml)

## What you get

* **One toolchain definition.** [`rust-toolchain.toml`](./rust-toolchain.toml)
  is read by both rustup and Nix. Nix users are pinned by `flake.lock`; rustup
  users track stable.
* **Fast, cached builds.** [crane](https://github.com/ipetkov/crane) builds
  the crate and caches dependency builds separately from your own source.
* **Checks in one command.** `nix flake check` builds the crate and runs
  [clippy](https://github.com/rust-lang/rust-clippy) (warnings denied),
  [rustfmt](https://github.com/rust-lang/rustfmt), the tests and `cargo doc`.
* **Formatting in one command.** `nix fmt` formats Nix and Rust files.
* **A dev shell** with `rust-analyzer`, and
  [bacon](https://github.com/Canop/bacon) for rebuild-on-save.
* **[direnv](https://direnv.net) support** via [`.envrc`](./.envrc).
* **CI** on Linux and macOS with GitHub Actions, plus a weekly pull request
  that updates `flake.lock`.
* **Docker, two ways.** A dev container for people without Nix, and a minimal
  production image via `nix build .#docker`.
* **Sensible Rust defaults.** Edition 2024, `unsafe_code = "forbid"`, and
  clippy's `pedantic` group enabled as warnings.

## Setup

### Start a project from the template

Click "Use this template" on GitHub, or from an empty directory:

```sh
nix flake init -t github:rpearce/nix-rust-template
```

Then rename the crate in `Cargo.toml`, and remove or update
`.github/FUNDING.yml` and `LICENSE`.

### With Nix

1. [Install Nix](https://nixos.org/download/)
2. [Enable flakes](https://wiki.nixos.org/wiki/Flakes) if your installer did
   not do so already
3. Optionally install [direnv](https://direnv.net) and
   [nix-direnv](https://github.com/nix-community/nix-direnv), then run
   `direnv allow` to enter the dev shell automatically

### With Docker (no Nix required)

```sh
docker compose run --rm app
```

This runs `nix run .#watch` in a container with your source tree mounted, so
edits on the host rebuild and rerun inside the container. The Nix store, its
caches and cargo's build directory live in named volumes, so only the first
run is slow. `docker compose down -v` throws them away.

`docker compose up` works too, but it does not forward your keystrokes, so
bacon's shortcuts only work with `docker compose run`. Any other command runs
through the same container:

```sh
docker compose run --rm app nix flake check
docker compose run --rm app nix develop
```

On Linux hosts, files the container creates inside your checkout (such as the
`result` symlink from `nix build`) are owned by root.

### With rustup only

rustup reads `rust-toolchain.toml` automatically, so `cargo build`,
`cargo test`, `cargo clippy` and friends work without Nix. You only lose the
Nix-side guarantees and `nix flake check`.

## Commands

| Command              | What it does                                              |
| -------------------- | --------------------------------------------------------- |
| `nix develop`        | Shell with the toolchain, `rust-analyzer` and `bacon`     |
| `nix build`          | Build the release binary into `./result/bin`              |
| `nix run`            | Build and run the binary                                  |
| `nix run .#watch`    | Rebuild and rerun on every source change (bacon)          |
| `nix flake check`    | Build, clippy, rustfmt, tests and docs                    |
| `nix fmt`            | Format Nix and Rust files                                 |
| `nix build .#docker` | Build a minimal production image (Linux only), then `docker load < result` |
| `nix flake update`   | Update the Nix inputs (nixpkgs, crane, rust-overlay)      |

Inside `nix develop`, the usual `cargo build`, `cargo test`, `cargo clippy`,
`cargo fmt` and `bacon` all work as well. For long-running programs such as
servers, use `bacon run-long` instead of `bacon run`.

## Customizing

* **Dependencies:** `cargo add <crate>` as usual. Nix picks them up from
  `Cargo.lock`.
* **Native libraries:** add them to `buildInputs` and `nativeBuildInputs` in
  `flake.nix`; the `commonArgs` comment shows where.
* **Exact Rust version:** set `channel = "1.98.1"` (or similar) in
  `rust-toolchain.toml`. Both rustup and Nix will follow it.
* **Fewer lints:** drop the `pedantic` line from `[lints.clippy]` in
  `Cargo.toml`.
* **Intel Macs:** nixpkgs unstable no longer supports `x86_64-darwin`. The
  comment above `systems` in `flake.nix` explains how to add it back.

## CI

[`ci.yml`](./.github/workflows/ci.yml) runs `nix flake check` and `nix build`
on Ubuntu and macOS, caching the Nix store between runs.

[`update-flake-lock.yml`](./.github/workflows/update-flake-lock.yml) opens a
pull request with fresh flake inputs every Monday. It needs "Allow GitHub
Actions to create and approve pull requests" enabled under the repository's
Actions settings. Pull requests opened with the default token do not trigger
CI; pass a personal access token or GitHub App token to the action if you want
that.
