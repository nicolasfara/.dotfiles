{
  description = "nicolasfara's nixos configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
  } @ inputs: let
    inherit (self) outputs;
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    });

    nixosModules = import ./modules/nixos;

    homeManagerModules = import ./modules/home-manager;
    
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager.users.nicolas.imports = [
              ./home-manager/home.nix
	    ];
            home-manager.extraSpecialArgs = {
              inherit inputs outputs;
	      pkgs = self.packages."x86_64-linux";
            };
          }
        ];
      };
    };
  };
}
