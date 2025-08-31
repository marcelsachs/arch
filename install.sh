#!/bin/bash

set -euo pipefail

source config.txt

run_in_chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

echo "==============================================="
echo "Arch Linux Automated Installation"
echo "==============================================="
echo "Disk: $DISK"
echo "Hostname: $HOSTNAME"
echo "User: $USER_NAME"
echo "Timezone: $TIMEZONE"
echo "==============================================="
echo "WARNING: This will COMPLETELY WIPE $DISK"
echo "Type 'yes' to continue:"
read -r confirm
[[ "$confirm" == "yes" ]] || { echo "Installation cancelled."; exit 1; }

echo "-> Partitioning disk..."
sgdisk -Z "$DISK"
sgdisk -n 1:0:+"$EFI_SIZE" -t 1:ef00 "$DISK"
sgdisk -n 2:0:+"$ROOT_SIZE" -t 2:8300 "$DISK"

echo "-> Formatting partitions..."
mkfs.fat -F32 "${DISK}p1"
mkfs.ext4 "${DISK}p2"

echo "-> Mounting partitions..."
mount "${DISK}p2" /mnt
mount --mkdir "${DISK}p1" /mnt/boot

echo "-> Updating mirrorlist..."
reflector --country "$COUNTRY" --latest 10 --fastest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo "-> Installing base system..."
pacstrap -K /mnt "${START_PACKAGES[@]}"

echo "-> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

cp config.txt /mnt/root/

echo "-> Configuring system..."

run_in_chroot "echo 'root:$ROOT_PASSWORD' | chpasswd"

run_in_chroot "ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime"
run_in_chroot "hwclock --systohc"

for loc in "${LOCALES[@]}"; do
    run_in_chroot "sed -i 's/^# *$loc/$loc/' /etc/locale.gen"
done
run_in_chroot "locale-gen"
run_in_chroot "echo 'LANG=$LANG' > /etc/locale.conf"

run_in_chroot "echo 'KEYMAP=$KEYMAP' > /etc/vconsole.conf"

run_in_chroot "echo '$HOSTNAME' > /etc/hostname"

echo "-> Configuring network..."
# Ethernet
ETHERNET_INTERFACE=$(ip -o link show | awk -F': ' '/: en|: eth/ {print $2}' | head -n 1 || true)
if [[ -n "$ETHERNET_INTERFACE" ]]; then
    cat > /mnt/etc/systemd/network/10-wired.network <<EOF
[Match]
Name=$ETHERNET_INTERFACE

[Network]
DHCP=yes
EOF
fi

WLAN_INTERFACE=$(ip -o link show | awk -F': ' '/: wl/ {print $2}' | head -n 1 || true)
if [[ -n "$WLAN_INTERFACE" ]]; then
    cat > /mnt/etc/systemd/network/20-wireless.network <<EOF
[Match]
Name=$WLAN_INTERFACE

[Network]
DHCP=yes
EOF
fi

if [[ -n "$WIFI_SSID" ]] && [[ -n "$WIFI_PASSWORD" ]]; then
    echo "-> Configuring WiFi..."
    mkdir -p /mnt/var/lib/iwd
    cat > /mnt/var/lib/iwd/${WIFI_SSID}.psk <<EOF
[Security]
PreSharedKey=$(echo -n "$WIFI_PASSWORD" | iwd-passphrase "$WIFI_SSID" | grep PreSharedKey= | cut -d= -f2)
EOF
fi

echo "-> Installing bootloader..."
run_in_chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
run_in_chroot "sed -i 's/^#\(GRUB_DISABLE_OS_PROBER=.*\)/\1/' /etc/default/grub"
run_in_chroot "grub-mkconfig -o /boot/grub/grub.cfg"

echo "-> Creating user $USER_NAME..."
run_in_chroot "useradd -m -d '$HOME_DIR' -s /bin/bash '$USER_NAME'"
run_in_chroot "echo '$USER_NAME:$USER_PASSWORD' | chpasswd"
run_in_chroot "echo '$USER_NAME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$USER_NAME"

if [[ ${#USER_PACKAGES[@]} -gt 0 ]]; then
    echo "-> Installing user packages..."
    run_in_chroot "pacman -Syu --noconfirm ${USER_PACKAGES[*]}"
fi

if [[ -n "$GITHUB_REPO" ]]; then
    echo "-> Cloning user repository..."
    run_in_chroot "su - $USER_NAME -c 'git clone $GITHUB_REPO'"
fi

echo "-> Enabling services..."
for service in "${SERVICES[@]}"; do
    run_in_chroot "systemctl enable $service"
done

rm -f /mnt/root/config.txt

echo "==============================================="
echo "Installation complete!"
echo "==============================================="
echo "You can now run:"
echo "  umount -R /mnt"
echo "  reboot"
echo "==============================================="
