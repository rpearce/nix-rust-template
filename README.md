# nix-rust-template

A reasonable way to start developing a reproducible
[Rust](https://www.rust-lang.org) project.

This reproducibility is enabled by [Nix](https://nixos.org) and
[Docker](https://www.docker.com).

## Features

This is a template repository; everything is customizable, and some helpful
defaults are included.

* Default rust extensions:
  * [`clippy-preview`](https://github.com/rust-lang/rust-clippy): A collection
    of lints to catch common mistakes and improve your Rust code
  * `rust-src`
  * `rustc-dev`
  * [`rustfmt`](https://github.com/rust-lang/rustfmt): A tool for formatting
    Rust code according to style guidelines
* Default dev tools:
  * [`rust-analyzer`](https://github.com/rust-analyzer/rust-analyzer): Excellent
    IDE support
  * [`cargo-watch`](https://github.com/watchexec/cargo-watch): Watches over your
    project's source for changes, and runs Cargo commands when they occur
  * [`cargo-edit`](https://github.com/killercup/cargo-edit): Extends Cargo to
    allow you to add, remove, and upgrade dependencies by modifying your
    `Cargo.toml` file from the command line
* [`naersk`](https://github.com/nix-community/naersk): Nix support for building
  cargo crates
* [`oxalica/rust-overlay`](https://github.com/oxalica/rust-overlay/): Pure and
  reproducible overlay for binary distributed rust toolchains

## Setup

### With Docker

#### With `docker compose` (recommended)

```sh
docker compose build
docker compose up
```

#### Without `docker compose`

```sh
docker build . -t nix-rust-template
docker volume create nix-rust-template-vol
docker run --rm -it -v $PWD:/service nix-rust-template:latest
```

### Without Docker

1. [Install nix](https://nixos.org/download.html)
1. [Install nix flakes](https://nixos.wiki/wiki/Flakes)

## Commands

If you are using Docker, prefix the following with `docker compose run --rm
app`; for example:

```sh
docker compose run --rm app nix run .#watch
```

* `nix build`: build the package
* `nix run` or `nix run .#app`: run the package
* `nix run .#watch`: watch the package for changes and rerun
* `nix develop`: enter a reproducible rust shell environment
  * How to watch for changes and rerun:
    ```sh
    cargo watch -w "./src/" -x "run"
    ```
