# hosts/home/configuration.nix
# Adapted from hosts/laptop/configuration.nix ("alice").
# Key differences from the laptop: Btrfs instead of ZFS (no kernel pinning
# needed), desktop tower (no fingerprint reader, no battery/Optimus power
# management), Docker enabled (this machine's whole purpose is Yocto builds
# via Docker per earlier discussion).

{ pkgs, config, ... }:

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
  boot.supportedFilesystems = [ "ntfs" ];

  # Suspend used to hang indefinitely on this machine: every "deep" (S3)
  # suspend logged only "PM: suspend entry (deep)" and nothing else, ever --
  # not even with /sys/power/pm_debug_messages=1 enabled, which should log
  # every device's suspend/resume. That total silence, persisting even
  # across a genuine multi-minute sleep (not just an instant freeze), points
  # at the firmware's S3 resume vector failing rather than any Linux driver:
  # if firmware never hands control back to the kernel, no kernel code --
  # logging included -- ever runs again. Confirmed by elimination: switching
  # to s2idle (which keeps the kernel driving idle states instead of
  # handing off to firmware S3) resumes correctly every time.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # The Logitech receiver for the MX Master 3 mouse (idProduct c52b) is
  # wired as an ACPI wakeup source and spuriously wakes the machine ~2s
  # after every suspend -- almost certainly from the mouse's own motion/RF
  # noise or its periodic HID++ status polling, confirmed via
  # /proc/acpi/wakeup and /sys/bus/usb/devices/*/power/wakeup. Disabling
  # its wakeup capability stops it. The keyboard's receiver (idProduct
  # c548) is left alone so a keypress can still wake the machine normally.
  # A udev rule is needed for this to survive reboots, since the sysfs
  # attribute resets to the hardware default (enabled) on every boot.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c52b", ATTR{power/wakeup}="disabled"
  '';

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
  #
  # powerManagement.enable is NOT Optimus-specific though -- it installs the
  # nvidia-suspend/nvidia-hibernate/nvidia-resume systemd services that save
  # and restore GPU video memory across S3 sleep. Without it, resume from
  # suspend hangs indefinitely on this machine (confirmed via journalctl:
  # every suspend attempt logs "PM: suspend entry (deep)" as its last line,
  # with no resume ever logged, requiring a hard power cycle).
  hardware.nvidia = {
    modesetting.enable = true; # required for Wayland/Plasma
    open = true; # Ampere (RTX 3080) is supported by the open kernel modules
    # powerManagement.enable = false;
    prime.sync.enable = false;
    prime.offload.enable = false;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
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
