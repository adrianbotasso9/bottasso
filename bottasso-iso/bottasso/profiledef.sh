#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="bottasso"
iso_label="BOTASSO OS"
iso_publisher="BOTASSO OS"
iso_application="BOTASSO OS"
iso_version="2026.11.12"
iso_arch="x86_64"
install_dir="arch"
bootmodes=('bios.syslinux'
           'uefi.grub')
pacman_conf="pacman.conf"
airootfs_image_type="erofs"
airootfs_image_tool_options=('-zlzma,109' -E 'ztailpacking')
bootstrap_tarball_compression=(xz -9e)
file_permissions=(
  ["/etc/shadow"]="0:0:400"
)
