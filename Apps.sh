#!/bin/bash

# ===============================================================================
# SCRIPT ÚNICO: instalar_apps.sh (GENERADO AUTOMÁTICAMENTE)
# Descripción: Este script instala una lista predefinida de aplicaciones
#              usando el gestor de paquetes 'yay' para CachyOS (Arch).
#              La lista de aplicaciones se generó automáticamente desde
#              tu sistema actual.
# ===============================================================================

# -------------------------------------------------------------------------------
# Lista de aplicaciones a instalar
# Puedes editar esta lista si quieres agregar o quitar paquetes.
# -------------------------------------------------------------------------------
APPS=(
7zip
accountsservice
adobe-source-han-sans-cn-fonts
adobe-source-han-sans-jp-fonts
adobe-source-han-sans-kr-fonts
alsa-firmware
alsa-plugins
alsa-utils
amd-ucode
asusctl
awesome-terminal-fonts
aylurs-gtk-shell-git
base
base-devel
bash-completion
bat
bind
blueman
bluez
bluez-hid2hci
bluez-libs
bluez-utils
brightnessctl
btop
btrfs-assistant
btrfs-progs
chwd
cpupower
cryptsetup
cups
cups-filters
cups-pdf
dart-sass
device-mapper
dhclient
diffutils
dmidecode
dmraid
dnsmasq
dosfstools
duf
e2fsprogs
efibootmgr
efitools
egl-wayland
envycontrol
ethtool
exfatprogs
f2fs-tools
fastfetch
ffmpegthumbnailer
file-roller
foomatic-db
foomatic-db-engine
foomatic-db-gutenprint-ppds
foomatic-db-nonfree
foomatic-db-nonfree-ppds
foomatic-db-ppds
fsarchiver
galculator
ghostscript
gimp
git
glances
gnome-keyring
google-chrome
gparted
grim
grimblast-git
gsfonts
gst-libav
gst-plugin-pipewire
gst-plugin-va
gst-plugins-bad
gst-plugins-ugly
gtk4-layer-shell
gtksourceview3
gutenprint
gvfs
gvfs-afc
gvfs-gphoto2
gvfs-mtp
gvfs-nfs
gvfs-smb
haveged
hdparm
hwdetect
hwinfo
hypridle
hyprland
hyprlock
hyprpicker
inetutils
iptables-nft
iwd
jfsutils
kitty
lazygit
less
lib32-mesa
lib32-vulkan-radeon
libdvdcss
libgsf
libgtop
libopenraw
libwnck3
light
logrotate
loupe
lsb-release
lsd
lsscsi
lvm2
man-db
man-pages
mdadm
meld
mesa-utils
micro
modemmanager
mtools
netctl
networkmanager
networkmanager-openvpn
nfs-utils
nilfs-utils
noto-color-emoji-fontconfig
noto-fonts
noto-fonts-cjk
noto-fonts-emoji
nss-mdns
ntp
nwg-look
opendesktop-fonts
openssh
os-prober
pacman-contrib
pamixer
papirus-icon-theme
pavucontrol
perl
pipewire-alsa
pipewire-pulse
pkgfile
plocate
plymouth
polkit-gnome
poppler-glib
power-profiles-daemon
pv
python
python-defusedxml
python-packaging
rebuild-detector
reflector
ripgrep
rofi
rog-control-center
rsync
rtkit
s-nail
sddm
sg3_utils
smartmontools
snapper
sof-firmware
splix
starship
stow
stremio
sudo
swaybg
swaync
switcheroo-control
swww
sysfsutils
system-config-printer
tela-circle-icon-theme-nord
texinfo
thunar-archive-plugin
thunar-media-tags-plugin
thunar-volman
timeshift
tldr
trash-cli
ttf-bitstream-vera
ttf-dejavu
ttf-hack-nerd
ttf-iosevka-nerd
ttf-iosevkaterm-nerd
ttf-jetbrains-mono-nerd
ttf-liberation
ttf-meslo-nerd
ttf-opensans
tumbler
ufw
unrar
unzip
upower
usb_modeswitch
usbutils
vi
vulkan-radeon
waypaper
wget
which
wireless-regdb
wireplumber
wl-clipboard
wlogout
woff2-font-awesome
wpa_supplicant
xdg-desktop-portal-hyprland
xdg-user-dirs
xf86-input-libinput
xf86-video-amdgpu
xfsprogs
xl2tpd
xorg-xhost
yad
yay
yazi
zenity
zoxide
ags-hyprpanel-git
catppuccin-gtk-theme-mocha
hyprprop-git
hyprsunset-git
python-gpustat
qogir-cursor-theme
sddm-sugar-candy-git
sddm-sugar-dark
ttf-ms-win11-auto
tumbler-extra-thumbnailers
wf-recorder-git
wl-color-picker
zinit
)

# -------------------------------------------------------------------------------
# Lógica de instalación (no es necesario modificar esta sección)
# -------------------------------------------------------------------------------

# Verificar si 'yay' está instalado.
if ! command -v yay &> /dev/null; then
    echo "Error: 'yay' no está instalado. Por favor, instálalo para continuar."
    exit 1
fi

echo "Iniciando la instalación de las siguientes aplicaciones:"
echo "${APPS[@]}"
echo "---"
echo "Se te pedirá confirmación una única vez antes de la instalación."
echo "---"

# Usar yay para instalar todos los paquetes de una vez.
# --needed: No reinstalar los paquetes que ya están instalados.
yay -S --needed "${APPS[@]}"

echo "¡Proceso de instalación completado! Revisa la salida para ver si hay errores."

