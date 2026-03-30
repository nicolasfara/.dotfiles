{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.networkmanager
    pkgs.networkmanagerapplet # Adds nm-connection-editor
    pkgs.wireguard-tools # Allows using wg and wg-quick commands
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  # Allow wireguard connections through firewall
  networking.firewall.checkReversePath = "loose";
}