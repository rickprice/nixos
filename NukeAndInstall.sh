#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Repo root: $REPO_DIR"

# /etc/nixos -> repo root (so flake.nix is at /etc/nixos/flake.nix)
NIXOS_DEST="/etc/nixos"

echo "Removing $NIXOS_DEST..."
sudo rm -rf "$NIXOS_DEST"
echo "Symlinking $REPO_DIR -> $NIXOS_DEST..."
sudo ln -s "$REPO_DIR" "$NIXOS_DEST"

echo ""
echo "Done. To apply the configuration, run:"
echo "  sudo nixos-rebuild switch --flake /etc/nixos#daw"
echo ""
echo "If flakes are not yet enabled on the system, use:"
echo "  sudo nixos-rebuild switch --flake /etc/nixos#daw --extra-experimental-features 'nix-command flakes'"
