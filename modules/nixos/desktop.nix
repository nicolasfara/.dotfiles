{ config, pkgs, ... }:

{
  # Keep OBS and its virtual-camera kernel setup together with the rest of
  # the desktop stack.
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  # networking.networkmanager.enable is set in wireguard.nix; not repeated here.

  # polkit backs SDDM/Plasma privilege-escalation dialogs; rtkit grants
  # PipeWire realtime scheduling priority. Both are desktop-session
  # prerequisites, not general system defaults.
  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us,it";
        variant = ",";
        options = "grp:alt_shift_toggle";
      };
    };

    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;

    printing = {
      enable = true;
      drivers = [ pkgs.hplipWithPlugin ];
    };

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # Network HP printer at 10.0.2.0, added via IPP Everywhere (driverless) --
  # no HPLIP PPD needed even though hplipWithPlugin stays installed above
  # for HP printers/scanners that don't support driverless IPP.
  hardware.printers.ensurePrinters = [
    {
      name = "HP_Color_LaserJet_MFP_M277dw";
      description = "HP Color LaserJet MFP M277dw - Studio";
      deviceUri = "ipp://10.0.2.0/ipp/print";
      model = "everywhere";
    }
  ];

  programs = {
    firefox.enable = true;

    obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      plugins = with pkgs.obs-studio-plugins; [
        droidcam-obs
      ];
    };
  };
}
