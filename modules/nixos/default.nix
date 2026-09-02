{
  base = import ./base.nix;
  desktop = import ./desktop.nix;
  devBoards = import ./dev-boards.nix;
  docker = import ./docker.nix;
  locale = import ./locale.nix;
  sanoid = import ./sanoid.nix;
  users = import ./users.nix;
  networking = import ./networking.nix;
}
