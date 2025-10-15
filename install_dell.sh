#!/bin/bash
# install_dell.sh - Arch Linux installation script for Dell Latitude E6410

set -euo pipefail

# ===============================================
# CONFIGURATION
# ===============================================
DISK="/dev/sda"
EFI_SIZE="512M"
ROOT_SIZE="142G"
HOSTNAME="dell"
USER_NAME="sachs"
USER_PASSWORD="dell"
ROOT_PASSWORD="root"
HOME_DIR="/$USER_NAME"
COUNTRY="Germany"
TIMEZONE="Europe/Berlin"
LOCALES=("en_US.UTF-8" "de_DE.UTF-8")
LANG="en_US.UTF-8"
KEYMAP="neoqwertz"
WIFI_SSID="WLAN-463866"
WIFI_PASSWORD="43904334"
GITHUB_REPO="https://github.com/marcelsachs/arch.git"

SERVICES=(
    "bluetooth"
    "cpupower"
    "iwd"
    "sshd"
    "systemd-networkd"
    "systemd-resolved"
)

PACKAGES=(
    "arm-none-eabi-binutils"
    "arm-none-eabi-gcc"
    "arm-none-eabi-gdb"
    "arm-none-eabi-newlib"
    "base"
    "base-devel"
    "bind"
    "bluez"
    "bluez-utils"
    "chromium"
    "cmake"
    "cpupower"
    "dmenu"
    "fastfetch"
    "feh"
    "gcc"
    "gdb"
    "git"
    "fastfetch"
    "i3"
    "i3status"
    "i3-wm"
    "intel-ucode"
    "iwd"
    "less"
    "libx11"
    "libxt"
    "linux"
    "linux-firmware"
    "lm_sensors"
    "man-db"
    "man-pages"
    "make"
    "mesa"
    "minicom"
    "nano"
    "openssh"
    "openocd"
    "parted"
    "pavucontrol"
    "pcmanfm"
    "pulseaudio"
    "pulseaudio-bluetooth"
    "python"
    "python-pip"
    "ranger"
    "screengrab"
    "stlink"
    "sudo"
    "tcpdump"
    "tree"
    "ttc-iosevka"
    "ttf-ibm-plex"
    "unzip"
    "usbutils"
    "usbview"
    "vim"
    "which"
    "wget"
    "xclip"
    "xorg-server"
    "xorg-init"
    "xorg-randr"
    "zathura-pdf-mupdf"
)

# ===============================================
# HELPER FUNCTIONS
# ===============================================
run_in_chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

# ===============================================
# MAIN INSTALLATION
# ===============================================
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

# ===============================================
# DISK SETUP (BIOS/MBR)
# ===============================================
echo "-> Partitioning disk..."
parted -s "$DISK" mklabel msdos
parted -s "$DISK" mkpart primary ext4 1MiB "$ROOT_SIZE"
parted -s "$DISK" set 1 boot on

echo "-> Formatting partitions..."
ROOT_PARTITION="${DISK}1"
mkfs.ext4 "$ROOT_PARTITION"

echo "-> Mounting partitions..."
mount "$ROOT_PARTITION" /mnt

# ===============================================
# BASE SYSTEM
# ===============================================
echo "-> Updating mirrorlist..."
reflector --country "$COUNTRY" --latest 10 --fastest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo "-> Installing base system..."
pacstrap -K /mnt "${PACKAGES[@]}"

echo "-> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ===============================================
# NETWORK CONFIGURATION
# ===============================================
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

# ===============================================
# SYSTEM CONFIGURATION
# ===============================================
echo "-> Configuring system..."
run_in_chroot "echo 'root:$ROOT_PASSWORD' | chpasswd"
run_in_chroot "ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime"
run_in_chroot "hwclock --systohc"

# Locale setup
for loc in "${LOCALES[@]}"; do
    run_in_chroot "sed -i 's/^#$loc/$loc/' /etc/locale.gen"
done
run_in_chroot "locale-gen"
run_in_chroot "echo 'LANG=$LANG' > /etc/locale.conf"
run_in_chroot "echo 'KEYMAP=$KEYMAP' > /etc/vconsole.conf"

# Hostname
run_in_chroot "echo '$HOSTNAME' > /etc/hostname"
run_in_chroot "echo -e '127.0.0.1 localhost\n::1 localhost' > /etc/hosts"

# ===============================================
# BOOTLOADER (GRUB for BIOS/Legacy Boot)
# ===============================================
echo "-> Installing GRUB bootloader..."
run_in_chroot "pacman -S --noconfirm grub"

# Install GRUB to the MBR (not partition)
run_in_chroot "grub-install --target=i386-pc $DISK"

# Generate GRUB configuration
run_in_chroot "grub-mkconfig -o /boot/grub/grub.cfg"

# ===============================================
# USER SETUP
# ===============================================
echo "-> Creating user $USER_NAME..."
run_in_chroot "useradd -m -d '$HOME_DIR' -s /bin/bash '$USER_NAME'"
run_in_chroot "echo '$USER_NAME:$USER_PASSWORD' | chpasswd"
run_in_chroot "echo '$USER_NAME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$USER_NAME"

# ===============================================
# SERVICES
# ===============================================
echo "-> Enabling services..."
for service in "${SERVICES[@]}"; do
    run_in_chroot "systemctl enable $service"
done

# Configure systemd-resolved DNS settings
run_in_chroot "sed -i '/^#DNS=/c\DNS=8.8.8.8 8.8.4.4' /etc/systemd/resolved.conf"
run_in_chroot "sed -i 's/^#FallbackDNS=/FallbackDNS=/' /etc/systemd/resolved.conf"

# ===============================================
# OPTIONAL: CLONE USER REPO
# ===============================================
if [[ -n "$GITHUB_REPO" ]]; then
    echo "-> Cloning user repository..."
    run_in_chroot "su - $USER_NAME -c 'git clone $GITHUB_REPO'"
fi

# ===============================================
# COMPLETION
# ===============================================
echo "==============================================="
echo "FINISHED!"
echo "==============================================="
echo "Now do:"
echo " umount -R /mnt"
echo " reboot"
echo "==============================================="
