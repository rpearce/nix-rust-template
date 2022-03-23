FROM nixos/nix

RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

WORKDIR /service
COPY . /service

RUN nix build

CMD ["nix", "run", ".#watch"]
