{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    zfs
    util-linux
    gptfdisk
    restic
    syncthing
    fprintd
    fprintd-tod
    libfprint
    libfprint-tod
    direnv
  ];

  # Enable ZSH as the default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.nix-ld.enable = true;

  virtualisation.docker = {
    enable = true;
  };
  users.users.nicolas.extraGroups = [ "docker" ];
}
