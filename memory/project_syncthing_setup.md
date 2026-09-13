---
name: project-syncthing-setup
description: Syncthing installation state — what's configured and what still needs device IDs filled in
metadata:
  type: project
---

Syncthing was installed on `daw` and `fwork` via `config/modules/syncthing.nix`, included in those two hosts in `flake.nix` (not `tprice` or `eric`). Runs as `fprice`.

Folder synced: `MarkDownDocuments.personal`
- Local path on both machines: `/home/fprice/Documents/Personal/Dropbox/FrederickDocuments/MarkDownDocuments.personal`
- Syncs between: `daw`, `fwork`, and Android device

Android device ID: `SVKN2P3-74JHTNE-JY5XVLL-DGAXLM7-RZJYB5M-IC63VWP-32DNUJP-SQ2YNAC` (already filled in)

**Still needed:** Real device ID for `daw` — currently a placeholder in `syncthing.nix`. `fwork` ID is filled in. Get them via:
- Web UI: `http://localhost:8384` → Actions → Show ID
- CLI: `sudo -u fprice syncthing cli config system status | grep myID`

Until these are filled in, `syncthing-init.service` will fail on each rebuild (harmless — `syncthing.service` itself runs fine).

**Why:** First-run race condition also caused `syncthing-init` to fail on `fwork` during the initial `nixos-rebuild switch`; this is a one-time issue that resolves itself after Syncthing has initialized once.
