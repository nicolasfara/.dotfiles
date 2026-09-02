{ pkgs, ... }:

# Installs NetworkManager and WireGuard tooling only; no tunnel/peers are
# declared here. Each host configures its own WireGuard connection via
# nmcli/the NetworkManager applet.
{
  environment.systemPackages = [
    pkgs.networkmanager
    pkgs.networkmanagerapplet # Adds nm-connection-editor
    pkgs.wireguard-tools # Allows using wg and wg-quick commands
  ];

  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  # Allow wireguard connections through firewall
  networking.firewall.checkReversePath = "loose";
}
