#!/bin/bash
# base_install.sh - Install minimal base packages for basic system with network/SSH

set -euo pipefail

source config.sh

echo "-> Installing base system..."
pacstrap -K /mnt "${PACKAGES[@]}"

echo "-> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
