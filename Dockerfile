# A development container for people who do not have Nix installed.
#
# The image only provides Nix itself. The Rust toolchain, tools and checks
# all come from the flake, exactly as they do outside Docker. See
# docker-compose.yml for the volumes that make repeated runs fast.
FROM nixos/nix:2.35.2

# Flakes are still behind a feature flag in Nix.
ENV NIX_CONFIG="experimental-features = nix-command flakes"

# On Linux hosts the bind-mounted checkout keeps the host user's ownership
# while Nix runs here as root, and Nix (via libgit2) refuses to read a git
# repository owned by someone else. Mark every directory as safe.
RUN printf '[safe]\n\tdirectory = *\n' > /etc/gitconfig

# Keep cargo's build artifacts out of the bind-mounted source tree so they
# never collide with builds made on the host.
ENV CARGO_TARGET_DIR=/target

WORKDIR /service

CMD ["nix", "run", ".#watch"]
