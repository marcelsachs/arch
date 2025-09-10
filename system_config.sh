#!/bin/bash
# system_config.sh - Configure system in chroot (timezone, locale, etc.)

set -euo pipefail

source config.sh

echo "-> Configuring system..."
echo 'root:$ROOT_PASSWORD' | chpasswd
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
for loc in "${LOCALES[@]}"; do
    sed -i 's/^# *$loc/$loc/' /etc/locale.gen
done
locale-gen
echo "root:$ROOT_PASSWORD" | chpasswd
echo "LANG=$LANG" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" > /etc/hosts
