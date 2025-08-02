{
  description = "nicolasfara's nixos configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
    }@inputs:
    let
      inherit (self) outputs;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system: {
          # Add custom packages/derivations here if needed
          # Example: myPackage = pkgs.callPackage ./pkgs/my-package {};
        }
      );

      nixosModules = import ./modules/nixos;

      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/laptop/configuration.nix
            self.nixosModules.sanoid
            home-manager.nixosModules.home-manager
            {
              # Allow unfree packages
              nixpkgs.config.allowUnfree = true;
              
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.nicolas.imports = [
                ./modules/home-manager/default.nix
              ];
              home-manager.extraSpecialArgs = {
                inherit inputs outputs;
              };
            }
          ];
        };
      };
    };
}
