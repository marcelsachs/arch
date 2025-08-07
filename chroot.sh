#!/bin/bash
set -euo pipefail
source config.txt

echo "root:$ROOT_PASSWORD" | chpasswd
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc
for loc in "${LOCALES[@]}"; do sed -i "s/^# *$loc/$loc/" /etc/locale.gen; done
locale-gen
echo "LANG=$LANG" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
ETHERNET_INTERFACE=$(ip -o link show | awk -F': ' '/: en|: eth/ {print $2}' | head -n 1 || true)
printf '[Match]\nName=%s\n\n[Network]\nDHCP=yes\n' "$ETHERNET_INTERFACE" > /etc/systemd/network/10-wired.network
WLAN_INTERFACE=$(ip -o link show | awk -F': ' '/: wl/ {print $2}' | head -n 1 || true)
printf '[Match]\nName=%s\n\n[Network]\nDHCP=yes\n' "$WLAN_INTERFACE" > /etc/systemd/network/20-wireless.network
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed -i 's/^#\(GRUB_DISABLE_OS_PROBER=.*\)/\1/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
useradd -m -d "$HOME_DIR" -s /bin/bash "$USER_NAME"
echo "$USER_NAME:$USER_PASSWORD" | chpasswd
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/$USER_NAME" > /dev/null
pacman -Syu --noconfirm "${USER_PACKAGES[@]}"
su - "$USER_NAME" -c "git clone '$GITHUB_REPO'"
systemctl enable "${SERVICES[@]}"
