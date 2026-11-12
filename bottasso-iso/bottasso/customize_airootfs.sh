#!/bin/bash
set -euo pipefail

# Apply os-release
cat /usr/share/bottasso/os-release/base > /etc/os-release

# Apply SDDM theme (logo and config)
mkdir -p /usr/share/sddm/themes/bottasso
cp /usr/share/bottasso/logotipos/bottasso-logo.png /usr/share/sddm/themes/bottasso/logo.png
cp /usr/share/bottasso/themes/bottasso.conf /usr/share/sddm/themes/bottasso/bottasso.conf
