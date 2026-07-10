# nixos
My NixOS configuration (flake-based)

## Machines

| Hostname | User    | Keyboard | Disk encryption |
|----------|---------|----------|-----------------|
| daw      | fprice  | Dvorak   | Yes (LUKS)      |
| fprice   | fprice  | Dvorak   | Yes (LUKS)      |
| tprice   | tprice  | QWERTY   | No              |
| eric     | eric    | QWERTY   | No              |

## Structure

```
flake.nix                        # Flake entry point (nixpkgs, home-manager, plasma-manager, disko)
etc/nixos/
  configuration.nix              # Shared system configuration (all machines)
  hardware-configuration.nix     # Shared hardware config (kernel modules, CPU)
config/
  disko/
    encrypted.nix                # Disk layout for daw and fprice (LUKS + ext4 on /dev/nvme0n1)
    plain.nix                    # Disk layout for tprice and eric (plain ext4 on /dev/nvme0n1)
  home-manager/
    home.nix                     # Home Manager config for fprice (daw, fprice)
    tprice.nix                   # Home Manager config for tprice
    eric.nix                     # Home Manager config for eric
NukeAndInstall.sh                # Bootstrap script (for rebuilding an existing daw install)
```

## Fresh install (any machine)

### 1. Boot the NixOS installer

Write the NixOS ISO to a USB drive and boot from it. Either the graphical or minimal ISO works. If using the graphical ISO, open a terminal from the desktop before proceeding.

### 2. Connect to the internet

Ethernet is detected automatically. For Wi-Fi:
```
sudo systemctl start wpa_supplicant
wpa_cli
> add_network
> set_network 0 ssid "YourNetwork"
> set_network 0 psk "YourPassword"
> enable_network 0
> quit
```

Verify connectivity:
```
ping -c 3 nixos.org
```

### 3. Enable Nix flakes for this session

The installer may not have flakes enabled by default:
```
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### 4. Clone this repo

```
nix-shell -p git
git clone https://github.com/rickprice/nixos.git /tmp/nixos
exit
```

### 5. Partition and format the disk

**For daw or fprice** (LUKS encryption — you will be prompted to set a passphrase):
```
sudo nix run github:nix-community/disko -- --mode disko /tmp/nixos/config/disko/encrypted.nix
```

**For tprice or eric** (no encryption):
```
sudo nix run github:nix-community/disko -- --mode disko /tmp/nixos/config/disko/plain.nix
```

Disko partitions, formats, and mounts everything under `/mnt` automatically. The disk used is `/dev/nvme0n1`.

### 6. Install NixOS

Replace `<hostname>` with `daw`, `fprice`, `tprice`, or `eric`:
```
sudo nixos-install --flake /tmp/nixos#<hostname>
```

You will be prompted to set a root password at the end.

### 7. Set user passwords

```
sudo nixos-enter --root /mnt
passwd fprice    # on daw or fprice
# or:
passwd tprice    # on tprice
passwd eric      # on eric
exit
```

### 8. Reboot into the new system

```
reboot
```

Remove the USB drive when prompted.

### 9. After first boot — put the repo in place

Log in, then clone the repo and run the bootstrap script to symlink it to `/etc/nixos`:
```
git clone https://github.com/rickprice/nixos.git ~/nixos
~/nixos/NukeAndInstall.sh
```

### 10. Rebuild to confirm everything is wired up

```
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```

If flakes are not yet enabled on the freshly booted system:
```
sudo nixos-rebuild switch --flake /etc/nixos#<hostname> --option extra-experimental-features 'nix-command flakes'
```

After this first rebuild, flakes will be enabled and you can use the shell alias for future rebuilds:
```
rebuild
```

## How it works

- `flake.nix` pins nixpkgs (`nixos-26.05`), home-manager (`release-26.05`), plasma-manager, and disko.
- Home Manager runs as a NixOS module — no separate `home-manager switch` needed.
- Disk layouts are declared in `config/disko/` and applied at install time. All machines use `/dev/nvme0n1`.
- `NukeAndInstall.sh` symlinks the repo root to `/etc/nixos` so `flake.nix` is available at `/etc/nixos/flake.nix`.
- `hardware-configuration.nix` contains kernel modules suited to Intel NVMe hardware. If a machine has significantly different hardware, run `nixos-generate-config --no-filesystems` on it after install and commit the result.

## Updating inputs

```
nix flake update          # update all inputs
nix flake update nixpkgs  # update only nixpkgs
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```
