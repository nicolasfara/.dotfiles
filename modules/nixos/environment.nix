{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
  ];

  # Enable ZSH as the default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.nix-ld.enable = true;

  virtualisation.docker = {
    enable = true;
  };

  services.udev.extraRules = ''
    # Espressif ESP32 USB JTAG/Serial debug unit
    SUBSYSTEM=="usb", ATTR{idVendor}=="303a", ATTR{idProduct}=="1001", MODE="0666", GROUP="dialout"
    # Other common ESP32 USB-to-serial chips
    SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6015", MODE="0666", GROUP="dialout"
  '';

  users.users.nicolas.extraGroups = [
    "docker"
    "dialout"
    "plugdev"
  ];

}
