# nix-rust-template

A reasonable way to start developing a reproducible
[Rust](https://www.rust-lang.org) project.

This reproducibility is enabled by [Nix](https://nixos.org/).

## Commands

* `nix build`: build the package
* `nix run`: run the package
* `nix develop`: enter a reproducible rust shell environment

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
* [`naersk`](https://github.com/nix-community/naersk): Nix support for building
  cargo crates
* [`oxalica/rust-overlay`](https://github.com/oxalica/rust-overlay/): Pure and
  reproducible overlay for binary distributed rust toolchains
