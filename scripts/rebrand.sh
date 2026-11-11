#!/usr/bin/env bash
# scripts/rebrand.sh
#
# Aplica la rebrand de CachyOS -> BOTASSO OS en un sistema vivo.
# Requiere privilegios de root (sudo).
#
# Uso:
#   sudo bash scripts/rebrand.sh
#
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$repo_root/src"

info() { echo "[rebrand] $*"; }

# 1/4 - Base de os-release: /usr/lib/os-release
info "1/4 - Base de os-release -> /usr/lib/os-release"
sudo cp "$src/os-release/base" /usr/lib/os-release
sudo chown root:root /usr/lib/os-release
sudo chmod 644 /usr/lib/os-release

# 2/4 - /etc/os-release -> enlace simbólico al base
info "2/4 - /etc/os-release -> enlace simbólico al base"
if [ -L /etc/os-release ]; then
  sudo rm /etc/os-release
fi
if [ -e /etc/os-release ]; then
  info "  -> respaldando /etc/os-release original"
  sudo cp /etc/os-release /etc/os-release.bottasso.bak
fi
sudo ln -s /usr/lib/os-release /etc/os-release

# 3/4 - Tema de login SDDM
info "3/4 - Tema SDDM"
sudo mkdir -p /usr/share/sddm/themes/bottasso
sudo cp "$src/themes/bottasso/bottasso.conf" /usr/share/sddm/themes/bottasso/bottasso.conf
sudo cp "$src/assets/logo/bottasso-logo.png" /usr/share/sddm/themes/bottasso/bottasso-logo.png
sudo chown -R root:root /usr/share/sddm/themes/bottasso
sudo chmod 644 /usr/share/sddm/themes/bottasso/bottasso.conf
sudo chmod 644 /usr/share/sddm/themes/bottasso/bottasso-logo.png

# 4/4 - Icono de la distro (LOGO=bottasso en /usr/share/pixmaps)
info "4/4 - Icono de la distro -> /usr/share/pixmaps"
sudo cp "$src/assets/logo/bottasso-logo.png" /usr/share/pixmaps/bottasso.png
sudo chown root:root /usr/share/pixmaps/bottasso.png
sudo chmod 644 /usr/share/pixmaps/bottasso.png

info "Rebrand aplicado correctamente. Revisa con: hostnamectl"
