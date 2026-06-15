# nixos
My NixOS configuration (flake-based)

## Structure

```
flake.nix                        # Flake entry point (nixpkgs, home-manager, plasma-manager)
etc/nixos/
  configuration.nix              # System configuration
  hardware-configuration.nix     # Generated hardware config (do not edit)
config/home-manager/
  home.nix                       # Home Manager configuration for fprice
NukeAndInstall.sh                # Bootstrap script
```

## Initial setup

Install NixOS on the machine using the USB installer, then add git to the default config:

```
sudo nano /etc/nixos/configuration.nix
```

Add `git` to `environment.systemPackages`, then rebuild:

```
sudo nixos-rebuild switch
```

Clone this repo:

```
git clone https://github.com/rickprice/nixos.git
cd nixos
```

Run the bootstrap script to symlink the repo into place:

```
./NukeAndInstall.sh
```

Apply the configuration. If flakes are not yet enabled on the fresh install:

```
sudo nixos-rebuild switch --flake /etc/nixos#daw --extra-experimental-features 'nix-command flakes'
```

On subsequent rebuilds (flakes will be enabled after the first switch):

```
sudo nixos-rebuild switch --flake /etc/nixos#daw
```

Or use the shell alias:

```
rebuild
```

## How it works

- `flake.nix` pins nixpkgs (`nixos-26.05`), home-manager (`release-26.05`), and plasma-manager.
- Home Manager runs as a NixOS module — no separate `home-manager switch` needed.
- `NukeAndInstall.sh` symlinks the repo root to `/etc/nixos` so `flake.nix` is available at `/etc/nixos/flake.nix`.
- After setup, `sudo nixos-rebuild switch --flake /etc/nixos#daw` rebuilds both the system and the home environment in one step.

## Updating inputs

```
nix flake update          # update all inputs
nix flake update nixpkgs  # update only nixpkgs
sudo nixos-rebuild switch --flake /etc/nixos#daw
```
