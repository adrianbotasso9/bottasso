#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# Perfil de construccion de la ISO de instalacion grafica de BOTASSO OS.
# Arranca a una sesion KDE grafica con el instalador.

iso_name="bottasso-installer"
iso_label="BOTASSO INSTALLER"
iso_publisher="BOTASSO OS"
iso_application="BOTASSO OS Installer"
iso_version="2026.11.12"
iso_arch="x86_64"
install_dir="arch"
bootmodes=('bios.syslinux'
           'uefi.grub')
pacman_conf="pacman.conf"
airootfs_image_type="erofs"
airootfs_image_tool_options=('-zlzma,109' -E 'ztailpacking')
bootstrap_tarball_compression=(xz -9e)

# (Ajuste opcional /etc/shadow omitido: mkarchiso falla al aplicarlo en
#  chroots recien creados; no es necesario para una ISO live.)
