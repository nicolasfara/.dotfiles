# Personal nixos setup

Getting started with

```bash
git clone git@github.com:nicolasfara/.dotfiles.git ~
cd ~/.dotfiles
sudo nixos-rebuild switch --flake ~/.dotfiles#laptop' # you can choose between {home|laptop|work}
```

## Configuration update

```bash
nix flake update
sudo nixos-rebuild switch --flake ~/.dotfiles#laptop' # you can choose between {home|laptop|work}
```

## Update or create secrets

```bash
nix-shell -p sops --run "sops secrets.yaml"
```

Note: execute the command at the same level of `secrets.yaml` or provide the path to it.

## Nixos Documentations

- [Nixos & Flakes Book](https://nixos-and-flakes.thiscute.world/)
