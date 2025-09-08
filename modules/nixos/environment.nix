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

  services.udev.extraRules = ''
    # Espressif ESP32 USB JTAG/Serial debug unit
    SUBSYSTEM=="usb", ATTR{idVendor}=="303a", ATTR{idProduct}=="1001", MODE="0666", GROUP="dialout"
    # Other common ESP32 USB-to-serial chips
    SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6015", MODE="0666", GROUP="dialout"
  '';

  users.users.nicolas.extraGroups = [ "docker" "dialout" "plugdev" ];
  
  # OBS Studio with DroidCam plugin
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      droidcam-obs
    ];
  };
}
