#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# customize_airootfs.sh — se ejecuta DENTRO del chroot de la live ISO de
# BOTASSO OS, justo despues de pacstrap y antes de construir el ISO.
# Hornea la rebrand y prepara el entorno grafico de instalacion con Calamares.
#
# Cambios vs la version con PyQt6:
#   - Elimina el instalador PyQt6 (python-pyqt6, bottasso-installer.*)
#   - Añade el instalador Calamares (cachyos-calamares-qt6-*)
#   - Configura el modulo de bootloader con Limine
#   - Añade la sesion Calamares al autostart de Plasma

set -euo pipefail

info(){ echo "[live] $*"; }

# ---------------------------------------------------------------------------
# 1) Horneo de la rebrand (os-release + tema SDDM + logo)
# ---------------------------------------------------------------------------
info "1/5 - Horneando rebrand..."
cp /usr/share/bottasso/os-release/base /usr/lib/os-release
ln -sfn /usr/lib/os-release /etc/os-release

mkdir -p /usr/share/sddm/themes/bottasso
cp /usr/share/bottasso/themes/bottasso/bottasso.conf \
   /usr/share/sddm/themes/bottasso/bottasso.conf
cp /usr/share/bottasso/assets/logo/bottasso-logo.png \
   /usr/share/sddm/themes/bottasso/logo.png
cp /usr/share/bottasso/assets/logo/bottasso-logo.png \
   /usr/share/pixmaps/bottasso.png

# ---------------------------------------------------------------------------
# 2) Entorno grafico: SDDM + objetivo grafico (KDE Plasma)
# ---------------------------------------------------------------------------
info "2/5 - Preparando entorno grafico..."
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf <<EOF
[General]
AutologinEnable = true
AutologinUser = root
MinimumTimeout = 0
Session = plasma

[Autologin]
Session = plasma
EOF

ln -sfn /usr/lib/systemd/system/graphical.target \
        /etc/systemd/system/default.target
systemctl enable sddm >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# 3) Configuracion basica del entorno live
# ---------------------------------------------------------------------------
info "3/5 - Configurando entorno live..."
hostnamectl set-hostname bottasso-live 2>/dev/null || true
ln -sfn /usr/share/zoneinfo/America/Santiago /etc/localtime
echo 'LANG=C.UTF-8' > /etc/locale.conf

# ---------------------------------------------------------------------------
# 4) Instalador grafico: Calamares (Qt6)
# ---------------------------------------------------------------------------
info "4/5 - Instalando instalador grafico Calamares..."

# Ensure Calamares and its Qt6 modules are installed
# (installed via packages.x86_64: cachyos-calamares + cachyos-calamares-qt6-*)

# Create the live session launcher (Autostart for KDE)
install -d -m 0755 /home/root/.config/autostart

cat > /home/root/.config/autostart/bottasso-calamares.desktop <<EOF
[Desktop Entry]
Type=Application
Name=BOTASSO OS Installer
Comment=BOTASSO OS Calamares installer
Exec=calamares
Icon=bottasso
Terminal=false
Categories=System;Installer;
EOF

# Copy the BOTASSO logo to the calamares resources path
install -d -m 0755 /usr/share/calamares/resources/images
install -m 0644 /usr/share/bottasso/assets/logo/bottasso-logo.png \
                   /usr/share/calamares/resources/images/bottasso-logo.png

# ---------------------------------------------------------------------------
# 5) Herramientas basicas de particionado / red
# ---------------------------------------------------------------------------
info "5/5 - Asegurando herramientas..."
systemctl enable NetworkManager >/dev/null 2>&1 || true
systemctl enable crond >/dev/null 2>&1 || true
systemctl enable chronyd >/dev/null 2>&1 || true

info "Terminado. Ejecuta calamares para instalar BOTASSO OS."
