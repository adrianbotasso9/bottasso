#!/usr/bin/env bash
# bottasso-launcher.sh — lanza el instalador grafico de BOTASSO OS
# desde el menu del escritorio KDE (respaldo del autostart).
set -euo pipefail
exec python3 /usr/share/bottasso/install/bottasso-installer.py
