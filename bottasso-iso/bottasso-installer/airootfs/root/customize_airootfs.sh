#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# customize_airootfs.sh — se ejecuta DENTRO del chroot de la live ISO de
# BOTASSO OS, justo despues de pacstrap y antes de construir el ISO.
# Hornea la rebrand y prepara el entorno grafico de instalacion.

set -euo pipefail

info(){ echo "[live] $*"; }

# ---------------------------------------------------------------------------
# 1) Horneo de la rebrand (os-release + tema SDDM + logo)
#    Los ficheros-FUENTE ya estan en /usr/share/bottasso/ (plantilla
#    profile/airootfs/ copiada a este directorio antes de esta etapa).
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

# Asegurar objetivo grafico, y activar el gestor de sesiones
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
# 4) El instalador grafico PyQt6 (app + desktop + recursos)
# ---------------------------------------------------------------------------
info "4/5 - Instalando instalador grafico..."
install -d -m 0755 /usr/share/bottasso/install
install -d -m 0755 /usr/local/bin
install -d -m 0755 /home/root/.config/autostart

install -m 0755 /usr/share/bottasso/install/install-bottasso.sh \
                   /usr/local/bin/install-bottasso.sh
install -m 0644 /usr/share/bottasso/install/bottasso-installer.desktop \
                   /home/root/.config/autostart/bottasso-installer.desktop
install -m 0644 /usr/share/bottasso/assets/logo/bottasso-logo.png \
                   /usr/share/icons/hicolor/64x64/apps/bottasso.png

# ---------------------------------------------------------------------------
# 5) Herramientas basicas de particionado / red
# ---------------------------------------------------------------------------
info "5/5 - Asegurando herramientas..."
systemctl enable NetworkManager >/dev/null 2>&1 || true
systemctl enable crond >/dev/null 2>&1 || true
systemctl enable chronyd >/dev/null 2>&1 || true

info "Ejecuta el instalador desde el escritorio KDE, o reinicia al binario."
