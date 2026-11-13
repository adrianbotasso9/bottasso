#!/usr/bin/env bash
# install-bottasso.sh — instalador de BOTASSO OS.
# Se ejecuta como root dentro de la live ISO y produce SÓLO salida por
# stdout, con líneas prefijadas para que la GUI (bottasso-installer.py) las
# pueda leer. Las líneas usadas:
#   [PB:NN]   progreso (0..100)
#   [MB:string]  mensaje de estado
#   [ERRO:string]  error (tambi[en] a stderr)
#   [LOG:string]  registro

set -euo pipefail

DASH_RULE="($([ -n "$(command -v getopt)" ] && getopt --test >/dev/null && echo -) || echo -)"
DISK=""
MODE="erase"
YES="0"

msg(){   echo "[MB]$1"; }
progress(){ echo "[PB]$1"; }
error(){ echo "[ERRO]$1" >&2; }
log(){   echo "[LOG]$1"; }

# ---------------------------------------------------------------
die(){ log "ERROR: $1"; echo "[ERROR]$1" >&2; exit 1; }

usage(){ cat <<'EOF'
BOTASSO OS Installer
  --disk <device>  Dispositivo a instalar (ej: /dev/nvme0n1)
  --mode <m>       erase | dualboot | manual  (default: erase)
  --yes            Aceptar automaticamente
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --disk)   [[ $# -ge 2 ]] || die "--disk requiere argumento"; DISK="$2"; shift 2;;
    --mode)   [[ $# -ge 2 ]] || die "--mode requiere argumento"; MODE="$2"; shift 2;;
    --yes)    YES=1; shift;;
    -h|--help) usage; exit 0;;
    *) die "argumento desconocido: $1";;
  esac
done
[[ -n "$DISK" ]] || { usage >&2; die "faltan argumentos"; }

msg "Instalando BOTASSO OS en ${DISK} (modo: ${MODE})"

# ---------------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then die "hay que ejecutarlo como root"; fi

UEFI=0
if [[ -d /sys/firmware/efi ]]; then UEFI=1; fi
msg "Modo: ${MODE}; EFI=${UEFI}"

# ---------------------------------------------------------------
if [[ ! -b "$DISK" ]]; then die "no existe el dispositivo ${DISK}"; fi

PART1="${DISK}p1"
PART2="${DISK}p2"

if [[ "$MODE" == "erase" || "$MODE" == "dualboot" ]]; then
  msg "Particionando ${DISK} (GPT: ESP + /root) ..."
  progress 5
  parted -s -- "$DISK" mklabel gpt 2>>/tmp/bottasso-parted.err || die "parted mklabel"
  parted -s -- "$DISK" rm "$PART1" 2>/dev/null || true
  parted -s -- "$DISK" rm "$PART2" 2>/dev/null || true
  parted -s -- "$DISK" mkpart ESP fat32 1MiB 550MiB
  parted -s -- "$DISK" set 1 esp on
  parted -s -- "$DISK" mkpart primary ext4 550MiB 100%
  progress 10
  mkfs.fat -F32 "$PART1" -n BOTASSO-ESP 2>>/tmp/bottasso-parted.err || die "mkfs.fat ESP"
  mkfs.ext4 -F "$PART2" -L bottasso-root 2>>/tmp/bottasso-parted.err || die "mkfs.ext4 root"
  progress 15
fi
[[ -b "$PART1" ]] || die "no se pudo crear ${PART1}"
[[ -b "$PART2" ]] || die "no se pudo crear ${PART2}"

# ---------------------------------------------------------------
WORK="$(mktemp -d)"
mount "$PART2" "$WORK" || die "montar raiz"
mkdir -p "$WORK/boot/efi"
if [[ "$UEFI" -eq 1 ]]; then mount "$PART1" "$WORK/boot/efi"; fi
progress 20

BOTASSO_PKGS=(
  base linux-cachyos cachyos-keyring cachyos-settings ananicy-cpp
  proton-cachyos-native limine syslinux grub linux mkinitcpio-archiso
  arch-install-scripts openssh btrfs-progs xfsprogs e2fsprogs sddm
  networkmanager plasma-desktop
)
msg "Instalando paquetes: ${BOTASSO_PKGS[*]} ..."
progress 30
if ! pacstrap -K "$WORK" "${BOTASSO_PKGS[@]}" >>/tmp/bottasso-pacstrap.log 2>&1; then
  die "pacstrap fallo"
fi
genfstab -U "$WORK" >> "$WORK/etc/fstab" 2>/dev/null || true
progress 40

# ---------------------------------------------------------------
msg "Configurando el nuevo sistema..."
progress 50

arch-chroot "$WORK" /bin/bash <<'EOF'
set -euo pipefail
echo 'bottasso' > /etc/hostname
ln -sfn /usr/share/zoneinfo/America/Santiago /etc/localtime
echo 'LANG=es_CL.UTF-8' > /etc/locale.conf
echo 'es_CL.UTF-8 UTF-8' > /etc/locale.gen
locale-gen >/dev/null 2>&1 || true
systemctl enable sddm >/dev/null 2>&1 || true
systemctl enable NetworkManager >/dev/null 2>&1 || true
systemctl enable crond >/dev/null 2>&1 || true
systemctl enable chronyd >/dev/null 2>&1 || true
EOF
progress 55

# ---------------------------------------------------------------
msg "Aplicando rebrand a la instalacion..."
cp -a /usr/share/bottasso "$WORK/usr/share/" 2>/dev/null || true
arch-chroot "$WORK" /bin/bash <<'EOF'
set -euo pipefail
cp /usr/share/bottasso/os-release/base /usr/lib/os-release
ln -sfn /usr/lib/os-release /etc/os-release
mkdir -p /usr/share/sddm/themes/bottasso
cp /usr/share/bottasso/themes/bottasso/bottasso.conf /usr/share/sddm/themes/bottasso/bottasso.conf
cp /usr/share/bottasso/assets/logo/bottasso-logo.png /usr/share/sddm/themes/bottasso/logo.png
cp /usr/share/bottasso/assets/logo/bottasso-logo.png /usr/share/pixmaps/bottasso.png
EOF
progress 60

# ---------------------------------------------------------------
msg "Instalando el gestor de arranque..."
if [[ "$UEFI" -eq 1 ]]; then
  grub-install --target=x86_64-efi --efi-directory=/boot/efi \
               --bootloader-id=BOTASSO --recheck --no-nvram \
               --removable >>/tmp/bottasso-grub.log 2>&1 || true
  mkdir -p /boot/grub
  cp /usr/share/grub/grub.cfg /boot/grub/ 2>/dev/null || true
  sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub 2>/dev/null || true
  grub-mkconfig -o /boot/grub/grub.cfg >>/tmp/bottasso-grub.log 2>&1 || true
else
  grub-install --target=i386-pc --boot-directory=/boot --root-password= >>/tmp/bottasso-grub.log 2>&1 || true
fi
progress 70

# ---------------------------------------------------------------
sync
msg "Instalacion completada."
progress 100
msg "El sistema fue instalado con exito."
umount -R "$WORK" 2>/dev/null || true
msg "Reinciendo en 5 segundos..."
sleep 5
reboot
