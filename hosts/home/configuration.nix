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

  # This machine never sleeps: it is an always-on desktop (Yocto builds,
  # syncthing, btrbk snapshots), so only the *display* is allowed to power
  # down on idle -- the system itself stays fully awake. (Firmware S3 on this
  # board never returns from its resume vector anyway; s2idle worked, but with
  # sleep disabled outright the mem_sleep_default kernel param is moot.)
  #
  # Enforced at three levels, because each can trigger a sleep independently:
  #
  # 1. systemd/logind refuses the sleep operations outright. Preferred over
  #    masking sleep.target/suspend.target: with the Allow* switches off,
  #    logind's CanSuspend()/CanHibernate() answer "na", so Plasma hides the
  #    Sleep/Hibernate entries instead of offering buttons whose systemd job
  #    then fails.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # 2. logind's own idle handling and the ACPI sleep/hibernate keys stay inert.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
  };

  # 3. Plasma's powerdevil, which is what actually acts on session idle. Set
  #    per-host here rather than in modules/home-manager/plasma.nix because
  #    the laptop shares that module and *does* want idle suspend on battery.
  #    "AC" is the profile a battery-less desktop always runs in.
  #    autoSuspend.idleTimeout is deliberately unset: plasma-manager asserts
  #    against pairing a timeout with the "nothing" action.
  home-manager.users.nicolas.programs.plasma.powerdevil.AC = {
    autoSuspend.action = "nothing";
    turnOffDisplay = {
      idleTimeout = 600; # screen off after 10 min idle
      idleTimeoutWhenLocked = 60; # ...or 1 min once the session is locked
    };
  };

  # The Valve Index is wired to DP-4 and is the reason the desktop used to come
  # back wrong from display standby -- it has nothing to do with NVIDIA sleep.
  #
  # An idle Index keeps its DP link half-alive: HPD is asserted, but the panel
  # controller is asleep, so the EDID read over AUX fails. NVIDIA then
  # fabricates a stub EDID -- manufacturer "NVD", product 0, year 1990, 0x0 cm
  # physical size, single 640x480 mode -- and hands *that* to DRM.
  #
  # The kernel flags VR headsets as non-desktop from an EDID quirk keyed on
  # Valve's real ids (VLV 0x91a8/0x91b0). Against an NVD stub the quirk never
  # matches, the connector is never marked non-desktop, and KWin therefore
  # treats the headset as an ordinary 640x480 monitor -- it had even recorded it
  # in kwinoutputconfig.json at x=-640 with the BenQ as replication source.
  # Every time the Index cycles its link (which a DPMS off/on across the card
  # reliably provokes) KWin re-probes, momentarily reports *zero* outputs
  # ("There are no outputs - creating placeholder screen" in every KDE client),
  # rebuilds the session from a no-screen state, then fails to allocate scanout
  # buffers on the NVIDIA EGL stack (GL_OUT_OF_MEMORY ->
  # GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT) and eventually crashes, taking
  # plasmashell and every running app down with it.
  #
  # Force the connector off so the phantom output never materialises. nvidia-drm
  # imports drm_helper_probe_single_connector_modes, which honours
  # connector->force, so this is respected -- unlike drm.edid_firmware, whose
  # loader (drm_edid_load_firmware) nvidia-drm does not import, which is why
  # supplying a real Index EDID to make the non-desktop quirk fire is not an
  # option here.
  #
  # Cost: VR needs this param dropped and a reboot. Nothing is lost today --
  # Steam/SteamVR is not installed on this host. Verify after rebooting with
  #   cat /sys/class/drm/card1-DP-4/status   # expect: disconnected
  boot.kernelParams = [ "video=DP-4:d" ];

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
  # powerManagement.enable is left off deliberately. All it does is install the
  # nvidia-suspend/nvidia-hibernate/nvidia-resume services that preserve GPU
  # video memory across S3, and this host has sleep disabled outright above --
  # so there is no suspend for them to service. Note this is *not* the fix for
  # the desktop coming back broken from display standby: that was the phantom
  # DP-4 output documented at boot.kernelParams above, which is a modesetting
  # problem, not a power-management one.
  #
  # This board also has an AMD Raphael iGPU (PCI 11:00.0 -> card2) with nothing
  # attached; both DisplayPort sinks hang off the 3080 (PCI 01:00.0 -> card1).
  # amdgpu stays loaded for VA-API. If output re-probes ever need narrowing
  # further, pin the compositor to the NVIDIA card with
  #   environment.sessionVariables.KWIN_DRM_DEVICES =
  #     "/dev/dri/by-path/pci-0000:01:00.0-card";
  hardware.nvidia = {
    modesetting.enable = true; # required for Wayland/Plasma
    open = true; # Ampere (RTX 3080) is supported by the open kernel modules
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
