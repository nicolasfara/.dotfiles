{
  sanoid = import ./sanoid.nix;
  env = import ./environment.nix;
  workstation = import ./workstation.nix;
  wireguard = import ./wireguard.nix;
}
