{
  description = "nicolasfara's nixos configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url = "github:ryantm/agenix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      agenix,
    }@inputs:
    let
      inherit (self) outputs;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      
      # Helper function to create NixOS system with common modules
      mkSystem = system: modules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs outputs; };
        modules = [
          agenix.nixosModules.default
          {
            # Install agenix package for any system
            environment.systemPackages = [ agenix.packages.${system}.default ];
            # Allow unfree packages globally
            nixpkgs.config.allowUnfree = true;
          }
        ] ++ modules;
      };
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
        # ---------------------------------
        # Laptop Configuration
        # ---------------------------------
        laptop = mkSystem "x86_64-linux" [
          ./hosts/laptop/configuration.nix
          self.nixosModules.sanoid
          self.nixosModules.env
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nicolas.imports = [
              ./modules/home-manager/default.nix
              agenix.homeManagerModules.default
            ];
            home-manager.users.nicolas.programs.onepassword-git = {
              enable = true;
              signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPacHq6GiFIEA4o0D4B74K20je+KeSxkuIUvr6oF4wJ";
            };
            home-manager.extraSpecialArgs = {
              inherit inputs outputs;
            };
          }
        ];
        # ---------------------------------
      };
    };
}
