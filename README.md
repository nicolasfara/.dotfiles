# Personal nixos setup

Getting started with

```bash
git clone git@github.com/nicolasfara/.dotfiles.git ~
cd ~/.dotfiles
sudo nixos-rebuild switch --flake ~/.dotfiles#laptop' # you can choose between {home|laptop|work}
```

## Configuration update

```bash
nix flake update
sudo nixos-rebuild switch --flake ~/.dotfiles#laptop' # you can choose between {home|laptop|work}
```

## Nixos Documentations

- [Nixos & Flakes Book](https://nixos-and-flakes.thiscute.world/)
