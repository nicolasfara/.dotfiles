# hosts/home/configuration.nix
# Adapted from hosts/laptop/configuration.nix ("alice").
# Key differences from the laptop: Btrfs instead of ZFS (no kernel pinning
# needed), desktop tower (no fingerprint reader, no battery/Optimus power
# management), Docker enabled (this machine's whole purpose is Yocto builds
# via Docker per earlier discussion).

{ pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader = {
    grub = {
      enable = true;
      devices = [ "nodev" ]; # Use this for UEFI
      efiSupport = true;
      useOSProber = true;
      # useOSProber dropped: single-OS install on this machine, no dual-boot
      # to detect. Add it back if that assumption changes.
    };
    efi.canTouchEfiVariables = true;
  };

  # No boot.kernelPackages pin here: that block on the laptop exists only to
  # find a kernel version compatible with out-of-tree ZFS modules. Btrfs is
  # in-tree, so the default kernel package is fine.

  # Btrfs subvolumes/mountpoints are declared in hosts/home/disko.nix and
  # wired in via disko.nixosModules.disko at the flake level -- no
  # fileSystems.* or ZFS options needed here.

  # Btrfs equivalent of the laptop's services.zfs.autoScrub.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [
      "/"
      "/data"
    ];
  };

  # Btrfs equivalent of the laptop's sanoid (ZFS-only) snapshot management.
  # Tune the retention numbers to taste; excludes /nix deliberately -- NixOS
  # generations already version /nix, snapshotting it too is redundant and
  # can desync from the bootloader's generation list.
  services.btrbk.instances."home" = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve = "14d";
      volume."/" = {
        subvolume = {
          "." = { };
          "home" = { };
        };
      };
    };
  };

  networking.hostName = "julia"; # rename to taste, e.g. to match the laptop's naming convention
  # networking.hostId dropped: that's a ZFS-only requirement (prevents
  # multi-import of a pool), not needed for Btrfs.

  # powerManagement.powertop and hardware.nvidia.powerManagement.finegrained
  # dropped: both are laptop-battery / Optimus-hybrid-graphics specific.
  # This is a single always-on discrete GPU desktop.
  hardware.nvidia = {
    modesetting.enable = true; # required for Wayland/Plasma
    open = true; # Ampere (RTX 3080) is supported by the open kernel modules
    prime.sync.enable = false;
    prime.offload.enable = false;
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    btrfs-progs
    # zfs and gptfdisk dropped: not needed without ZFS, and disko now owns
    # partitioning declaratively instead of manual gdisk/parted sessions.
  ];

  # This value determines the NixOS release from which the default settings
  # for stateful data were taken. This is a *new* install, so this should be
  # the current stable release at install time -- NOT copied from the
  # laptop's value, which reflects when that machine was first installed.
  # 26.05 "Yarara" is current as of this writing; verify at actual install time.
  system.stateVersion = "26.05";
}
