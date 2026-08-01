{ pkgs, ... }:

{
  # Single source of truth for the "nicolas" account: identity, group
  # membership and its NixOS-level (as opposed to home-manager) packages.
  # Group membership previously accreted across environment.nix and
  # workstation.nix; keep additions here instead of re-opening
  # users.users.nicolas.extraGroups from other modules.
  users.users.nicolas = {
    isNormalUser = true;
    description = "Nicolas Farabegoli";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "dialout"
      "plugdev"
    ];
    packages = [
      pkgs.kdePackages.kate
    ];
  };
}
