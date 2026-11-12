#!/bin/bash
set -euo pipefail
cat /usr/share/bottasso/os-release/base > /etc/os-release
mkdir -p /usr/share/sddm/themes/bottasso
cp /usr/share/bottasso/logotipos/bottasso-logo.png /usr/share/sddm/themes/bottasso/logo.png 2>/dev/null || true
