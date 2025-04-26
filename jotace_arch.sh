#!/bin/bash

# =============================================================================
# Script: jotace_arch.sh
# Descripción: Este script es un INSTALADOR de aplicaciones y configuraciones.
# Función: Su propósito es instalar en la máquina actual los paquetes de
#          Pacman y Yay/AUR listados abajo.
#          También puede configurar el shell del usuario a zsh (si era bash/fish)
#          y añadir al usuario al grupo 'video', previa confirmación.
#          Omite automáticamente los paquetes que ya están instalados (--needed).
#          Pacman/Yay solicitarán confirmación para la instalación y dependencias
#          (incluyendo opcionales).
#          Usa 'dialog' para prompts interactivos (Sí/No) si está disponible.
# Uso: Ejecutar como tu usuario normal (no root): ./jotace_arch.sh
# =============================================================================

# Salir inmediatamente si un comando falla.
set -e

# --- Funciones Auxiliares ---

# Verifica si los comandos necesarios están disponibles
check_commands() {
    local missing_commands=()
    # Añadimos 'dialog' a la lista de comandos a verificar
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            # No consideramos dialog como un error fatal si falta, ya que hay fallback
            if [ "$cmd" != "dialog" ]; then
                missing_commands+=("$cmd")
            fi
        fi
    done

    if [ ${#missing_commands[@]} -gt 0 ]; then
        echo "Error: Comandos necesarios no encontrados: ${missing_commands[*]}" >&2
        return 1 # Indica fallo
    fi
    return 0 # Indica éxito
}

# Instala Yay desde AUR si no está presente
install_yay() {
    echo "Comando 'yay' no encontrado. Intentando instalarlo desde AUR."
    echo "Esto requiere 'git' y el grupo de paquetes 'base-devel'."

    local confirm_yay_install="N" # Valor por defecto
    local yay_install_confirmed=false # Flag para saber si se confirmó via TUI

    # --- Intentar usar prompts interactivos ---
    if command -v dialog &> /dev/null; then
        echo "Usando dialog para solicitar confirmación de instalación de Yay..."
        if dialog --yesno "Yay no está instalado. ¿Quieres instalarlo ahora desde AUR?\n\nEsto requiere 'git' y el grupo de paquetes 'base-devel'." 10 60 2>&1 >/dev/tty; then
            confirm_yay_install="S"
            yay_install_confirmed=true
        else
            echo "Confirmación recibida (dialog): No, o cancelado." >&2
            echo "Instalación de Yay omitida por el usuario." >&2
            return 1
        fi
    else
        echo "'dialog' no encontrado. Usando prompt de texto para solicitar confirmación de instalación de Yay."
        read -p "¿Quieres instalar Yay ahora? (s/N): " text_confirm_yay_install
        confirm_yay_install=${text_confirm_yay_install:-N}
    fi

    # --- Procesar la confirmación ---
    if "$yay_install_confirmed" || [[ "$confirm_yay_install" =~ ^[Ss]$ ]]; then
        echo "Confirmación recibida: Sí."
        if ! command -v git &> /dev/null || ! command -v makepkg &> /dev/null; then
             echo "Error: Comandos 'git' o 'makepkg' no encontrados. No se puede instalar Yay." >&2
             echo "Asegúrate de que 'git' y el grupo 'base-devel' estén instalados." >&2
             return 1
        fi

        local yay_dir="yay-bin" # Usamos yay-bin para un binario precompilado
        local yay_aur_url="https://aur.archlinux.org/${yay_dir}.git"
        local original_dir=$(pwd) # Guardar directorio actual

        echo "Clonando $yay_aur_url..."
        # Crear un directorio temporal seguro para la clonación y construcción
        local temp_build_dir
        temp_build_dir=$(mktemp -d)
        trap 'rm -rf "$temp_build_dir"' EXIT # Asegurar limpieza del directorio temporal

        cd "$temp_build_dir" || { echo "Error: No se pudo entrar al directorio temporal $temp_build_dir"; return 1; }

        if git clone "$yay_aur_url" "$yay_dir"; then
            echo "Clonación exitosa. Construyendo e instalando Yay..."
            cd "$yay_dir" || { echo "Error: No se puede entrar al directorio $yay_dir"; return 1; }

            echo "Se te pedirá la contraseña de sudo para 'makepkg -si'."
            # makepkg -si instala las dependencias y el paquete.
            if makepkg -si --noconfirm; then # Usamos --noconfirm aquí porque el usuario ya confirmó la instalación de Yay
                echo "Yay instalado exitosamente."
                cd "$original_dir" # Volver al directorio original
                rm -rf "$temp_build_dir" # Limpiar directorio temporal
                trap - EXIT # Quitar el trap de limpieza
                return 0 # Éxito
            else
                echo "Error durante la ejecución de makepkg -si para Yay." >&2
                cd "$original_dir" # Volver al directorio original
                # La limpieza la hará el trap EXIT
                return 1 # Fallo
            fi
        else
            echo "Error clonando el repositorio AUR de Yay." >&2
            cd "$original_dir" # Volver al directorio original
             # La limpieza la hará el trap EXIT
            return 1 # Fallo
        fi
    else
        echo "Instalación de Yay omitida por el usuario." >&2
        return 1
    fi
}

# --- Listas de Paquetes ---
# (Estas listas son las que estaban en tu archivo jotace_arch.sh)

# Pacman packages list
read -r -d '' PACMAN_PACKAGES_LIST << 'EOF_PACMAN_LIST'
7zip
bat
bc
bind
blueman
bluez
bluez-utils
brightnessctl
btop
btrfs-progs
cliphist
cups
cups-browsed
cups-filters
cups-pdf
dialog
easyeffects
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
hyprutils
kitty
lazygit
light
loupe
micro
ntfs-3g
nwg-look
pamixer
papirus-icon-theme
polkit-gnome
power-profiles-daemon
pulsemixer
qt5-wayland
rofi
sddm
starship
stow
swaybg
swaylock
swaync
swww
system-config-printer
tela-circle-icon-theme-nord
thunar-archive-plugin
thunar-media-tags-plugin
thunar-volman
timeshift
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
unzip
upower
usb_modeswitch
usbutils
uwsm
waybar
xdg-desktop-portal-hyprland
yad
yazi
zam-plugins-lv2
zenity
zoxide
zsh
EOF_PACMAN_LIST

# Yay/AUR packages list
read -r -d '' YAY_PACKAGES_LIST << 'EOF_YAY_LIST'
asusctl
asusctltray-git
bat-asus-battery-bin
catppuccin-gtk-theme-mocha
envycontrol
hyprprop-git
ntfs-3g-system-compression-git
qogir-cursor-theme
rog-control-center
sddm-theme-sugar-candy-git
thorium-browser-bin
timeshift-autosnap
tumbler-extra-thumbnailers
waypaper
wl-color-picker
wlogout
zinit
EOF_YAY_LIST

# --- Lógica Principal de Instalación ---

echo "============================================================"
echo "  Inicio: Instalación de Paquetes y Configuración"
echo "============================================================"
echo "Este script instalará paquetes de Pacman y Yay/AUR."
echo " - Ignorará paquetes ya instalados (--needed)."
echo " - Se te pedirá contraseña de sudo cuando sea necesario."
echo " - Pacman y Yay solicitarán confirmación para instalar paquetes,"
echo "   dependencias y dependencias opcionales."
echo " - Las preguntas de Sí/No de este script usarán 'dialog' (TUI)"
echo "   si está disponible, o prompts de texto normales."
echo ""
echo "Asegúrate de ejecutar este script como tu usuario normal (no root)."
echo "============================================================"
echo ""
sleep 2 # Pausa breve

# Verificar comandos necesarios al inicio
# Incluimos dialog aquí para que la función check_commands sepa de él
if ! check_commands pacman git makepkg getent chsh usermod whoami dialog; then
    echo "Faltan comandos esenciales (pacman, git, makepkg, getent, chsh, usermod, whoami)." >&2
    echo "Por favor, instálalos e inténtalo de nuevo." >&2
    exit 1
fi

# Instalar paquetes de Pacman
# Eliminamos líneas vacías antes de pasar a pacman
PACMAN_PACKAGES_TO_INSTALL=$(echo "$PACMAN_PACKAGES_LIST" | grep -v '^$' | sort -u)
if [ -n "$PACMAN_PACKAGES_TO_INSTALL" ]; then
    echo "--- [1/3] Instalando paquetes de Pacman ---"
    echo "Se necesitará la contraseña de sudo para 'pacman -Syu'."
    echo "Pacman te pedirá confirmación para proceder."
    # Pasamos la lista filtrada a pacman
    if echo "$PACMAN_PACKAGES_TO_INSTALL" | sudo pacman -Syu --needed -; then
        echo "--- Paquetes de Pacman procesados exitosamente ---"
    else
        echo "--- Advertencia: Ocurrió un error durante la instalación de paquetes de Pacman ---" >&2
        echo "--- Continuando con los siguientes pasos... ---"
    fi
    echo "" # Espacio
else
    echo "--- [1/3] No hay paquetes de Pacman en la lista. Saltando. ---"
    echo "" # Espacio
fi

# Instalar paquetes de Yay/AUR
# Eliminamos líneas vacías antes de pasar a yay
YAY_PACKAGES_TO_INSTALL=$(echo "$YAY_PACKAGES_LIST" | grep -v '^$' | sort -u)
if [ -n "$YAY_PACKAGES_TO_INSTALL" ]; then
    echo "--- [2/3] Instalando paquetes de Yay/AUR ---"
    # Verificar si yay está instalado, instalar si no
    if ! command -v yay &> /dev/null; then
        echo "Comando 'yay' no encontrado."
        if ! install_yay; then
            echo "--- Error: No se pudieron instalar los paquetes de Yay/AUR porque la instalación de Yay falló o fue omitida. ---" >&2
            # Continuamos con las configuraciones si es posible
        else
             # Si install_yay tuvo éxito, yay ya está disponible
             echo "Yay instalado. Procediendo a instalar paquetes de Yay/AUR desde la lista."
             echo "Ejecutando 'yay -S --needed'. Yay solicitará confirmación y posiblemente contraseña de sudo."
             if echo "$YAY_PACKAGES_TO_INSTALL" | yay -S --needed -; then
                  echo "--- Paquetes de Yay/AUR procesados exitosamente ---"
             else
                  echo "--- Advertencia: Ocurrió un error durante la instalación de paquetes de Yay/AUR ---" >&2
             fi
        fi
    else
        # Yay ya estaba instalado
        echo "Comando 'yay' encontrado. Procediendo a instalar paquetes de Yay/AUR desde la lista."
        echo "Ejecutando 'yay -S --needed'. Yay solicitará confirmación y posiblemente contraseña de sudo."
        if echo "$YAY_PACKAGES_TO_INSTALL" | yay -S --needed -; then
             echo "--- Paquetes de Yay/AUR procesados exitosamente ---"
        else
             echo "--- Advertencia: Ocurrió un error durante la instalación de paquetes de Yay/AUR ---" >&2
        fi
    fi
     echo "" # Espacio
else
    echo "--- [2/3] No hay paquetes de Yay/AUR en la lista. Saltando. ---"
     echo "" # Espacio
fi


# --- [3/3] Configuraciones Adicionales ---

echo "--- [3/3] Realizando configuraciones adicionales (shell y grupo de usuario) ---"

# Obtener el nombre del usuario actual (el que ejecuta el script)
CURRENT_USER=$(whoami)

# Verificar si el usuario actual no es root
if [ "$CURRENT_USER" = "root" ]; then
    echo "Error: Este script debe ejecutarse como un usuario normal, no como root." >&2
    echo "Omitiendo configuraciones de shell y grupo." >&2
else
    echo "Usuario actual detectado: $CURRENT_USER"
    echo ""

    # Preguntar si se desean realizar las configuraciones adicionales
    perform_extra_configs=false
    if command -v dialog &> /dev/null; then
        if dialog --yesno "¿Deseas intentar configurar zsh como shell predeterminado (si usas bash/fish) y añadir el usuario '$CURRENT_USER' al grupo 'video'?" 10 70 2>&1 >/dev/tty; then
            perform_extra_configs=true
        fi
    else
        read -p "¿Deseas intentar configurar zsh y añadir al grupo 'video'? (s/N): " confirm_extra
        if [[ "${confirm_extra:-N}" =~ ^[Ss]$ ]]; then
            perform_extra_configs=true
        fi
    fi

    if $perform_extra_configs; then
        echo "Procediendo con las configuraciones adicionales..."
        echo ""

        # 1. Cambiar shell a zsh si es bash o fish
        # Primero, asegurarnos de que zsh esté instalado (ya debería estar por la lista de pacman, pero verificamos).
        if ! command -v zsh &> /dev/null; then
            echo "Advertencia: El comando 'zsh' no fue encontrado, aunque debería estar en la lista de Pacman." >&2
            echo "Intentando instalarlo de nuevo..."
            if echo "zsh" | sudo pacman -S --needed -; then
                echo "'zsh' instalado ahora."
            else
                echo "Error: No se pudo instalar 'zsh'. No se cambiará el shell." >&2
            fi
        fi

        # Si zsh está ahora disponible, intentamos cambiar el shell
        if command -v zsh &> /dev/null; then
            ZSH_PATH=$(command -v zsh)
            CURRENT_SHELL=$(getent passwd "$CURRENT_USER" | cut -d: -f7)
            echo "Shell actual de $CURRENT_USER: $CURRENT_SHELL"
            echo "Shell zsh encontrado en: $ZSH_PATH"

            if [[ "$CURRENT_SHELL" == */bash ]] || [[ "$CURRENT_SHELL" == */fish ]]; then
                echo "Intentando cambiar shell de $CURRENT_USER a zsh..."
                echo "Se necesitará la contraseña de sudo para 'chsh'."
                if sudo chsh -s "$ZSH_PATH" "$CURRENT_USER"; then
                    echo "Shell de $CURRENT_USER cambiado a zsh exitosamente. El cambio surtirá efecto en la próxima sesión."
                else
                    echo "Error: No se pudo cambiar el shell de $CURRENT_USER a zsh con chsh." >&2
                    echo "Puedes intentarlo manualmente: chsh -s $ZSH_PATH $CURRENT_USER" >&2
                fi
            elif [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
                 echo "El shell de $CURRENT_USER ya es zsh. No se necesita cambio."
            else
                echo "El shell de $CURRENT_USER no es bash ni fish ($CURRENT_SHELL). No se realizará el cambio automático a zsh."
            fi
        else
            echo "No se pudo cambiar el shell a zsh porque el comando 'zsh' no está disponible." >&2
        fi

        echo "" # Espacio antes de la siguiente acción

        # 2. Añadir usuario al grupo video
        # Verificar si el grupo video existe
        if getent group video &> /dev/null; then
            # Verificar si el usuario ya está en el grupo
            if groups "$CURRENT_USER" | grep -q '\bvideo\b'; then
                 echo "El usuario $CURRENT_USER ya pertenece al grupo 'video'."
            else
                echo "Intentando añadir usuario $CURRENT_USER al grupo 'video'..."
                echo "Se necesitará la contraseña de sudo para 'usermod'."
                if sudo usermod -aG video "$CURRENT_USER"; then
                    echo "Usuario $CURRENT_USER añadido al grupo 'video' exitosamente."
                    echo "Es posible que necesites cerrar sesión y volver a iniciarla para que el cambio surta efecto."
                else
                    echo "Error: No se pudo añadir al usuario $CURRENT_USER al grupo 'video' con usermod." >&2
                fi
            fi
        else
            echo "El grupo 'video' no existe en este sistema. No se añadirá al usuario." >&2
        fi
    else
        echo "Configuraciones adicionales (shell zsh, grupo video) omitidas por el usuario."
    fi

fi # Fin de la verificación si el usuario no es root

echo ""
echo "============================================================"
echo "  Proceso de instalación y configuración finalizado."
echo "============================================================"

exit 0
