#!/bin/bash
set -e

# Función para instalar Yay si no está presente
install_yay() {
    # Verifica dependencias para instalar Yay
    if ! command -v git &> /dev/null || ! command -v makepkg &> /dev/null; then
         echo "Error: 'git' y 'makepkg' (del grupo base-devel) son necesarios para instalar yay." >&2
         return 1
    fi

    # Pide confirmación al usuario para instalar Yay
    read -p "Yay no encontrado. ¿Instalar yay-bin desde AUR? (s/N): " confirm_yay
    if [[ ! "$confirm_yay" =~ ^[Ss]$ ]]; then
        echo "Instalación de Yay omitida." >&2
        return 1 # Falla si el usuario no confirma
    fi

    # Crea un directorio temporal seguro
    local tmp_dir
    tmp_dir=$(mktemp -d)
    # Asegura la limpieza del directorio temporal al salir o en caso de error
    trap 'echo "Limpiando directorio temporal..."; rm -rf "$tmp_dir"' EXIT

    echo "Clonando yay-bin..."
    # Clona el repositorio de yay-bin (binario precompilado, más rápido)
    if git clone --depth 1 "https://aur.archlinux.org/yay-bin.git" "$tmp_dir/yay-bin"; then
        cd "$tmp_dir/yay-bin" || return 1 # Entra al directorio clonado
        echo "Construyendo e instalando yay (se pedirá contraseña de sudo si es necesario)..."
        # Instala usando makepkg. --noconfirm aquí es aceptable porque el usuario ya confirmó la instalación de Yay.
        # makepkg pedirá sudo si necesita instalar dependencias o el paquete final.
        if ! makepkg -si --noconfirm; then
             echo "Error durante la instalación de Yay con makepkg." >&2
             # El trap se encargará de la limpieza
             return 1
        fi
        cd "$OLDPWD" || return 1 # Vuelve al directorio original
        # Desactiva y elimina el directorio temporal explícitamente tras el éxito
        trap - EXIT
        rm -rf "$tmp_dir"
        echo "Yay instalado exitosamente."
        return 0 # Éxito
    else
        echo "Error clonando el repositorio de yay-bin." >&2
        # El trap se encargará de la limpieza
        return 1 # Falla
    fi
}

# Lista única de todos los paquetes (Repositorios oficiales y AUR)
read -r -d '' ALL_PACKAGES << EOF_PACKAGES
7zip
asusctl
asusctltray-git
bat
bat-asus-battery-bin
bc
bind
blueman
bluez
bluez-utils
brightnessctl
btop
btrfs-progs
catppuccin-gtk-theme-mocha
cliphist
cups
cups-browsed
cups-filters
cups-pdf
dialog
easyeffects
envycontrol
eza
fastfetch
ffmpegthumbnailer
file-roller
galculator
ghostscript
git
gnome-keyring
gparted
grim
grub-btrfs
gst-libav
gst-plugin-pipewire
gst-plugins-bad
gst-plugins-ugly
gtk4-layer-shell
gvfs
gvfs-afc
gvfs-gphoto2
gvfs-mtp
gvfs-nfs
gvfs-smb
hyprcursor
hyprgraphics
hypridle
hyprland
hyprland-protocols
hyprland-qt-support
hyprland-qtutils
hyprlock
hyprpicker
hyprprop-git
hyprutils
kitty
lazygit
light
loupe
micro
ntfs-3g
ntfs-3g-system-compression-git
nwg-look
pamixer
papirus-icon-theme
polkit-gnome
power-profiles-daemon
pulsemixer
qogir-cursor-theme
qt5-wayland
rofi
rog-control-center
sddm
sddm-theme-sugar-candy-git
starship
stow
swaybg
swaylock
swaync
swww
system-config-printer
tela-circle-icon-theme-nord
thorium-browser-bin
thunar-archive-plugin
thunar-media-tags-plugin
thunar-volman
timeshift
timeshift-autosnap
tldr
trash-cli
tree
ttf-font-awesome
ttf-hack-nerd
ttf-iosevka-nerd
ttf-iosevkaterm-nerd
ttf-jetbrains-mono-nerd
ttf-liberation
ttf-meslo-nerd
tumbler
tumbler-extra-thumbnailers
unzip
upower
usb_modeswitch
usbutils
uwsm
waybar
waypaper
wl-color-picker
wlogout
xdg-desktop-portal-hyprland
yad
yazi
zam-plugins-lv2
zenity
zinit
zoxide
zsh
EOF_PACKAGES

# Verifica si Yay está instalado, si no, intenta instalarlo
if ! command -v yay &> /dev/null; then
    if ! install_yay; then
        echo "No se puede continuar sin Yay." >&2
        exit 1
    fi
fi

# Prepara la lista final de paquetes: elimina líneas vacías y duplicados
PACKAGES_TO_INSTALL=$(echo "$ALL_PACKAGES" | grep -v '^[[:space:]]*$' | sort -u)

# Verifica si hay paquetes en la lista
if [ -z "$PACKAGES_TO_INSTALL" ]; then
    echo "No hay paquetes especificados en la lista para instalar."
    exit 0
fi

echo "Iniciando la instalación de paquetes con Yay..."
echo "Se te pedirá confirmación antes de instalar/actualizar."
echo "Se omitirán los paquetes que ya estén instalados y actualizados (--needed)."
echo "Se preguntará por dependencias opcionales (--ask 4)."
echo "Se pedirá contraseña de sudo cuando sea necesario."

# Ejecuta Yay para instalar los paquetes desde la lista
# Se quitó --noconfirm para que pida confirmación general
# --ask 4 sigue pidiendo confirmación para dependencias opcionales
echo "$PACKAGES_TO_INSTALL" | yay -Syu --needed --ask 4 --removemake --nocleanmenu --nodiffmenu --noeditmenu -

echo "Instalación completada."
exit 0
