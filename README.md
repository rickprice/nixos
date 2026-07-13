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

### 3. Clone this repo

```
nix-shell -p git
git clone https://github.com/rickprice/nixos.git /tmp/nixos
exit
```

### 4. Partition and format the disk

**For daw or fprice** (LUKS encryption — you will be prompted to set a passphrase):
```
sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --mode disko /tmp/nixos/config/disko/encrypted.nix
```

**For tprice or eric** (no encryption):
```
sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --mode disko /tmp/nixos/config/disko/plain.nix
```

Disko partitions, formats, and mounts everything under `/mnt` automatically. The disk used is `/dev/nvme0n1`.

### 5. Activate swap

Disko formats a 16 GB swap partition (or LVM logical volume for the encrypted layout) during step 4, but does not always activate it in the live installer environment. Activate it manually before installing:

**For daw or fprice** (encrypted — LVM logical volume):
```
sudo swapon /dev/vg/swap
```

**For tprice or eric** (plain — partition):
```
sudo swapon /dev/nvme0n1p2
```

Verify it is active:
```
swapon --show
```

### 6. Install NixOS

Replace `<hostname>` with `daw`, `fprice`, `tprice`, or `eric`. The `--option` flags limit parallelism to match what the installed config enforces, preventing OOM kills during the build:
```
sudo nixos-install --flake /tmp/nixos#<hostname> --option max-jobs 2 --option cores 2
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

## Installing on a disk set up externally (e.g. by the NixOS installer)

The normal install uses disko to partition and generate `fileSystems` entries. If the disk was partitioned by some other means (e.g. the NixOS graphical installer), the disko module will still try to generate `fileSystems` based on what it expects and may not match what is actually on disk.

To handle this, capture the real filesystem layout and remove disko from the machine entry in `flake.nix`:

### 1. Generate a hardware configuration from the mounted system

With the target partitions mounted under `/mnt`:
```
nixos-generate-config --root /mnt --show-hardware-config > /tmp/nixos/etc/nixos/hardware-configuration.nix
```

This replaces the shared `hardware-configuration.nix` with one that includes real `fileSystems` entries for the actual partition layout.

### 2. Remove the disko module for that machine in `flake.nix`

Disko must not be included when it did not create the partitions, because it would generate conflicting `fileSystems` entries. Edit `flake.nix` and remove `disko.nixosModules.disko` and the disko disk config (e.g. `./config/disko/encrypted.nix`) from that machine's module list.

### 3. Install as normal

```
sudo nixos-install --flake /tmp/nixos#<hostname>
```

> **Note:** The modified `hardware-configuration.nix` is machine-specific. Commit it only if this machine will always use the same partition layout, or keep it local.

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
