{
  description = "NixOS configuration for daw";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager, ... }: {
    nixosConfigurations.daw = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./etc/nixos/configuration.nix
        ./config/modules/midi-daemon.nix
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [
            (final: prev: {
              midisnoop = prev.qt5.callPackage ./config/packages/midisnoop.nix { };
              midi-daemon = prev.callPackage ./config/packages/midi-daemon.nix { };
              volumepanningstereo-lv2 = prev.callPackage ./config/packages/volumepanningstereo-lv2.nix { };
              name-time-period = prev.callPackage ./config/packages/name-time-period.nix { };
            })
          ];
        }
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.fprice = import ./config/home-manager/home.nix;
          home-manager.sharedModules = [
            plasma-manager.homeModules.plasma-manager
          ];
        }
      ];
    };
  };
}
