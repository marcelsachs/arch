```
(boot from live arch.iso image from USB.)

git clone https://github.com/marcelsachs/arch.git
cd arch
vim config.txt
chmod +x install.sh
./install.sh

locale-gen
cp i3status
sway
foot
wmenu
i3status
base-devel
libx11
libxt
gcc
gdb
lsusb
xorg-xwayland


echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
sudo systemctl restart systemd-resolved
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

directly configure
sway, foot, i3status
