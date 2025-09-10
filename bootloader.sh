#!/bin/bash
# bootloader.sh - Setup systemd-boot

set -euo pipefail

source config.sh

get_partition_name() {
    echo "${DISK}p${1}"
}

echo "-> Installing bootloader (systemd-boot)..."
bootctl install
ROOT_PARTUUID=$(blkid -s PARTUUID -o value $(get_partition_name 2))
cat << EOF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=$ROOT_PARTUUID rw
EOF
cat << EOF > /boot/loader/loader.conf
default arch.conf
timeout 4
console-mode max
editor  no
EOF
