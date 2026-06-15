#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Repo root: $REPO_DIR"

# /etc/nixos -> repo/etc/nixos
NIXOS_SRC="$REPO_DIR/etc/nixos"
NIXOS_DEST="/etc/nixos"

echo "Removing $NIXOS_DEST..."
sudo rm -rf "$NIXOS_DEST"
echo "Symlinking $NIXOS_SRC -> $NIXOS_DEST..."
sudo ln -s "$NIXOS_SRC" "$NIXOS_DEST"

# ~/.config/home-manager -> repo/config/home-manager
HM_SRC="$REPO_DIR/config/home-manager"
HM_DEST="$HOME/.config/home-manager"

echo "Removing $HM_DEST..."
rm -rf "$HM_DEST"
echo "Symlinking $HM_SRC -> $HM_DEST..."
ln -s "$HM_SRC" "$HM_DEST"

echo "Done."
