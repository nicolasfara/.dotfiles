{ pkgs, ... }:

{
  # Minimal packages that must exist outside any user's home-manager profile
  # (e.g. available to root during system activation). Interactive user
  # tools (git, wget, etc.) live in modules/home-manager instead.
  environment.systemPackages = with pkgs; [
    vim
    (python3.withPackages (python-pkgs: with python-pkgs; [
      requests
    ]))
  ];

  # Enable ZSH as the default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.nix-ld.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
