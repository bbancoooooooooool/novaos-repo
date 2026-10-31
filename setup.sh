#!/bin/sh
# One-time setup for NovaOS systems installed before the update repo existed:
# adds the [novaos] repo to pacman, then updates the system and installs NovaOS Boost and NovaOS Update.
#   curl -fsSL https://raw.githubusercontent.com/bbancoooooooooool/novaos-repo/main/setup.sh | sudo sh
set -e
if [ "$(id -u)" -ne 0 ]; then
  echo "Run it with sudo:  curl -fsSL https://raw.githubusercontent.com/bbancoooooooooool/novaos-repo/main/setup.sh | sudo sh" >&2
  exit 1
fi
if ! grep -q '^\[novaos\]' /etc/pacman.conf; then
  printf '\n[novaos]\nSigLevel = Optional TrustAll\nServer = https://raw.githubusercontent.com/bbancoooooooooool/novaos-repo/main/$arch\n' >> /etc/pacman.conf
  echo "Added the [novaos] update repo to /etc/pacman.conf"
fi
pacman -Syu --noconfirm --needed novaos-boost novaos-update
echo "Done. From now on, open \"NovaOS Update\" from the menu (or the dock) and press Update now."
