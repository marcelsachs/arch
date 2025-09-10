#!/bin/bash
set -euo pipefail

source cfg.txt

get_partition_name() {
    echo "${1}p${2}"
}

run_in_chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

echo "==============================================="
echo "Arch Linux Installation"
echo "==============================================="
echo "Disk: $DISK"
echo "Hostname: $HOSTNAME"
echo "User: $USER_NAME"
echo "Timezone: $TIMEZONE"
echo "==============================================="
echo "WARNING: WILL WIPE $DISK"
echo "Type 'yes' to continue:"
read -r confirm
[[ "$confirm" == "yes" ]] || { echo "Installation cancelled."; exit 1; }

echo "-> Partitioning disk..."
sgdisk -Z "$DISK"
sgdisk -n 1:0:+"$EFI_SIZE" -t 1:ef00 "$DISK"
sgdisk -n 2:0:+"$ROOT_SIZE" -t 2:8300 "$DISK"

echo "-> Formatting partitions..."
EFI_PARTITION=$(get_partition_name "$DISK" "1")
ROOT_PARTITION=$(get_partition_name "$DISK" "2")
mkfs.fat -F32 "$EFI_PARTITION"
mkfs.ext4 "$ROOT_PARTITION"

echo "-> Mounting partitions..."
mount "$ROOT_PARTITION" /mnt
mount --mkdir "$EFI_PARTITION" /mnt/boot

echo "-> Updating mirrorlist..."
reflector --country "$COUNTRY" --latest 10 --fastest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo "-> Installing base system..."
pacstrap -K /mnt "${PACKAGES[@]}"

echo "-> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
cp cfg.txt /mnt/root/

echo "-> Configuring network..."
cat << EOF > /mnt/etc/systemd/network/20-wired.network
[Match]
Name=en* eth*

[Network]
DHCP=yes
EOF
cat << EOF > /mnt/etc/systemd/network/25-wireless.network
[Match]
Name=wl*

[Network]
DHCP=yes
EOF
run_in_chroot "mkdir -p /etc/iwd"
cat << EOF > /mnt/etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF
cat << EOF > "/mnt/var/lib/iwd/$WIFI_SSID.psk"
[Security]
Passphrase=$WIFI_PASSWORD
EOF

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
run_in_chroot "echo -e '127.0.0.1 localhost\n::1 localhost\n127.0.1.1 $HOSTNAME.localdomain $HOSTNAME' > /etc/hosts"

echo "-> Installing bootloader (systemd-boot)..."
run_in_chroot "bootctl install"
ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PARTITION")
cat << EOF > /mnt/boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=$ROOT_PARTUUID rw
EOF
cat << EOF > /mnt/boot/loader/loader.conf
default arch.conf
timeout 4
console-mode max
editor  no
EOF

echo "-> Creating user $USER_NAME..."
run_in_chroot "useradd -m -d '$HOME_DIR' -s /bin/bash '$USER_NAME'"
run_in_chroot "echo '$USER_NAME:$USER_PASSWORD' | chpasswd"
run_in_chroot "echo '$USER_NAME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$USER_NAME"

echo "-> Enabling services..."
for service in "${SERVICES[@]}"; do
    run_in_chroot "systemctl enable $service"
done

if [[ -n "$GITHUB_REPO" ]]; then
    echo "-> Cloning user repository..."
    run_in_chroot "su - $USER_NAME -c 'git clone $GITHUB_REPO'"
fi

rm -f /mnt/root/cfg.txt

echo "==============================================="
echo "FINISHED!"
echo "==============================================="
echo "Now do:"
echo " umount -R /mnt"
echo " reboot"
echo "==============================================="
