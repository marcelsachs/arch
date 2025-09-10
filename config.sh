# config.sh - Configuration variables

export DISK="/dev/nvme0n1"
export EFI_SIZE="512M"
export ROOT_SIZE="420G"
export HOSTNAME="arch"
export USER_NAME="sachs"
export USER_PASSWORD=""
export ROOT_PASSWORD="root"
export HOME_DIR="/$USER_NAME"
export COUNTRY="Germany"
export TIMEZONE="Europe/Berlin"
export LOCALES=("en_US.UTF-8" "de_DE.UTF-8")
export LANG="en_US.UTF-8"
export KEYMAP="neoqwertz"
export WIFI_SSID="WLAN-463866"
export WIFI_PASSWORD="43904334"
export GITHUB_REPO="https://github.com/marcelsachs/mybag.git"

export SERVICES=(
    "cpupower"
    "iwd"
    "sshd"
    "systemd-networkd"
    "systemd-resolved"
)

export PACKAGES=(
    "base"
    "cpupower"
    "git"
    "intel-ucode"
    "iwd"
    "less"
    "linux"
    "linux-firmware"
    "lm_sensors"
    "man-db"
    "man-pages"
    "make"
    "nano"
    "openssh"
    "sudo"
    "ttc-iosevka"
    "which"
    "wget"
    "wmenu"
)
