{
  description = "NixOS configuration for daw, tprice, and eric";

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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager, disko, ... }:
  let
    commonModules = [
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
            images-matching-subdirectories = prev.callPackage ./config/packages/images-matching-subdirectories.nix { };
            background-picker = prev.callPackage ./config/packages/background-picker.nix { };
            md-to-svg = prev.callPackage ./config/packages/md-to-svg.nix { };
            markdown-timesheet = prev.callPackage ./config/packages/markdown-timesheet.nix { };
            csvargs = prev.callPackage ./config/packages/csvargs.nix { };
            inappropriate-video-handler = prev.callPackage ./config/packages/inappropriate-video-handler.nix { };
            # Patch jobviewer.py to treat implicitclass:// as a remote printer scheme
            # so "Document printed" notifications are sent for auto-discovered printers.
            system-config-printer = prev.system-config-printer.overrideAttrs (oldAttrs: {
              postPatch = (oldAttrs.postPatch or "") + ''
                substituteInPlace jobviewer.py \
                  --replace-fail "if scheme not in ['socket', 'ipp', 'http', 'smb']:" \
                                 "if scheme not in ['socket', 'ipp', 'ipps', 'http', 'smb', 'implicitclass']:"
              '';
            });
          })
        ];
      }
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.fprice = import ./config/home-manager/home.nix;
        home-manager.users.tprice = import ./config/home-manager/tprice.nix;
        home-manager.users.eric = import ./config/home-manager/eric.nix;
        home-manager.sharedModules = [
          plasma-manager.homeModules.plasma-manager
        ];
      }
    ];
    mkHost = hostname: diskModule: extraModules: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = commonModules ++ [
        disko.nixosModules.disko
        diskModule
        ({ lib, ... }: {
          networking.hostName = lib.mkForce hostname;
          services.xserver.xkb.layout = lib.mkForce "us";
          services.xserver.xkb.variant = lib.mkForce "";
          console.keyMap = lib.mkForce "us";
        })
      ] ++ extraModules;
    };
    mkDvorakHost = hostname: diskModule: extraModules: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = commonModules ++ [
        disko.nixosModules.disko
        diskModule
        ({ lib, ... }: { networking.hostName = lib.mkForce hostname; })
      ] ++ extraModules;
    };
  in
  {
    nixosConfigurations.daw    = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = commonModules ++ [
        disko.nixosModules.disko
        ./config/disko/encrypted.nix
      ];
    };
    nixosConfigurations.fprice = mkDvorakHost "fprice" ./config/disko/encrypted.nix [ ];
    nixosConfigurations.tprice = mkHost "tprice" ./config/disko/plain.nix [ ];
    nixosConfigurations.eric   = mkHost "eric"   ./config/disko/plain.nix [ ];
  };
}
