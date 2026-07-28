{
  description = "nicolasfara's nixos configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      home-manager,
      plasma-manager,
      sops-nix,
      nix4vscode,
      disko,
    }@inputs:
    let
      inherit (self) outputs;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkSystem =
        {
          system ? "x86_64-linux",
          hostModules,
          resticBucket,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs outputs; };
          modules = [
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            self.nixosModules.env
            self.nixosModules.workstation
            self.nixosModules.wireguard
            {
              nixpkgs = {
                config.allowUnfree = true;
                overlays = [
                  nix4vscode.overlays.default
                ];
              };

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs outputs; };
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                  plasma-manager.homeModules.plasma-manager
                ];
                users.nicolas = {
                  imports = [ ./modules/home-manager/default.nix ];
                  programs.restic.bucketName = resticBucket;
                  programs.onepassword = {
                    enable = true;
                    signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPacHq6GiFIEA4o0D4B74K20je+KeSxkuIUvr6oF4wJ";
                  };
                };
              };
            }
          ]
          ++ hostModules;
        };
    in
    {
      packages = forAllSystems (system: {
        # Add custom packages/derivations here if needed
        # Example: myPackage = pkgs.callPackage ./pkgs/my-package {};
      });

      nixosModules = import ./modules/nixos;

      nixosConfigurations = {
        # ---------------------------------
        # Laptop Configuration
        # ---------------------------------
        laptop = mkSystem {
          resticBucket = "nixos-alice-backup";
          hostModules = [
            nixos-hardware.nixosModules.dell-xps-15-9530-nvidia
            nixos-hardware.nixosModules.common-pc-laptop
            nixos-hardware.nixosModules.common-pc-laptop-ssd
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-gpu-intel
            nixos-hardware.nixosModules.common-gpu-nvidia
            ./hosts/laptop/configuration.nix
            self.nixosModules.sanoid
          ];
        };
        # ---------------------------------
        home = mkSystem {
          resticBucket = "nixos-julia-backup";
          hostModules = [
            disko.nixosModules.disko
            ./hosts/home/disko.nix
            nixos-hardware.nixosModules.common-cpu-amd
            nixos-hardware.nixosModules.common-gpu-nvidia
            nixos-hardware.nixosModules.common-pc-ssd
            ./hosts/home/configuration.nix
          ];
        };
      };
    };
}
