#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Repo root: $REPO_DIR"

# This flake defines nixosConfigurations for daw, fwork, tprice, and eric;
# pick the one matching this machine, either via $1 or the current hostname.
KNOWN_HOSTS="daw fwork tprice eric"
TARGET_HOST="${1:-$(hostname)}"
if ! grep -qw "$TARGET_HOST" <<< "$KNOWN_HOSTS"; then
  echo "error: '$TARGET_HOST' is not one of this flake's hosts ($KNOWN_HOSTS)." >&2
  echo "Pass the right one explicitly: $0 <daw|fwork|tprice|eric>" >&2
  exit 1
fi

# /etc/nixos -> repo root (so flake.nix is at /etc/nixos/flake.nix)
NIXOS_DEST="/etc/nixos"

echo "Removing $NIXOS_DEST..."
sudo rm -rf "$NIXOS_DEST"
echo "Symlinking $REPO_DIR -> $NIXOS_DEST..."
sudo ln -s "$REPO_DIR" "$NIXOS_DEST"

echo ""
echo "Done. To apply the configuration, run:"
echo "  sudo nixos-rebuild switch --flake /etc/nixos#$TARGET_HOST"
echo ""
echo "If flakes are not yet enabled on the system, use:"
echo "  sudo nixos-rebuild switch --flake /etc/nixos#$TARGET_HOST --option extra-experimental-features 'nix-command flakes'"
