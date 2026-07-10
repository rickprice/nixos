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

Boot the NixOS installer ISO, then open a terminal.

**1. Enable networking** (if not already connected):
```
sudo systemctl start wpa_supplicant   # for Wi-Fi; or just plug in ethernet
```

**2. Clone this repo:**
```
nix-shell -p git
git clone https://github.com/rickprice/nixos.git /tmp/nixos
```

**3. Partition and format the disk using disko:**

For **daw** or **fprice** (LUKS encryption):
```
sudo nix run github:nix-community/disko -- --mode disko /tmp/nixos/config/disko/encrypted.nix
```

For **tprice** or **eric** (no encryption):
```
sudo nix run github:nix-community/disko -- --mode disko /tmp/nixos/config/disko/plain.nix
```

Disko partitions, formats, and mounts everything under `/mnt` automatically.

**4. Install NixOS:**

Replace `<hostname>` with `daw`, `fprice`, `tprice`, or `eric`:
```
sudo nixos-install --flake /tmp/nixos#<hostname>
```

**5. Set passwords, then reboot:**
```
sudo nixos-enter --root /mnt
passwd fprice    # or tprice / eric depending on the machine
exit
reboot
```

**6. After first boot — symlink the repo into place:**
```
git clone https://github.com/rickprice/nixos.git ~/nixos
sudo ./~/nixos/NukeAndInstall.sh
```

**7. Subsequent rebuilds:**
```
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```

Or use the shell alias:
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
