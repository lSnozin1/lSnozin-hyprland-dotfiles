#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

git clone --depth 1 https://github.com/Thang1191/Miku-Dating-Sim-GRUB-Theme.git "$TMP_DIR/miku-grub"
sudo "$TMP_DIR/miku-grub/install.sh"

sudo install -Dm644 "$SCRIPT_DIR/weird-linux.png" /boot/grub/themes/Miku-Dating-Sim/icons/weird-linux.png
sudo cp -a /etc/grub.d/40_custom "/etc/grub.d/40_custom.bak.$(date +%Y%m%d%H%M%S)"
sudo install -Dm755 "$SCRIPT_DIR/40_custom" /etc/grub.d/40_custom

sudo chmod -x /etc/grub.d/10_linux /etc/grub.d/30_os-prober /etc/grub.d/30_uefi-firmware /etc/grub.d/31_efi_bootnext 2>/dev/null || true
sudo grub-mkconfig -o /boot/grub/grub.cfg
