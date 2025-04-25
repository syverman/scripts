#!/bin/bash
set -e

# ==============================================================================
# Script: pc_origen.sh
# Descripción: Este script es un GENERADOR de un script de instalación.
# Función: Su propósito principal es crear un archivo llamado
#          'jotace_arch.sh' en la máquina de origen. Este script generado
#          contiene las listas de todos los paquetes instalados explícitamente
#          (tanto de Pacman como de Yay/AUR) de la máquina actual.
#          El script generado 'jotace_arch.sh' puede ser copiado y
#          ejecutado en otras máquinas Arch-based para replicar la
#          instalación de aplicaciones, incluyendo la configuración de zsh
#          y la adición al grupo video.
# Uso: Ejecutar sin argumentos (./pc_origen.sh) o con el argumento
#      'create' (./pc_origen.sh create) para generar el script de
#      instalación.
# ==============================================================================

# Nombre del archivo de salida para el script de instalación
INSTALL_SCRIPT_NAME="jotace_arch.sh"

# --- Validación del sistema ---
if [ "$(grep "^ID=" /etc/os-release | cut -d= -f2-)" != "arch" ]; then
    echo "Este script está diseñado para sistemas basados en Arch Linux. Abortando." >&2
    exit 1
fi

# --- Funciones Auxiliares (incluidas en el script generado) ---

# Verifica si los comandos necesarios están disponibles
check_commands() {
    local missing_commands=()
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            if [ "$cmd" != "dialog" ]; then
                missing_commands+=("$cmd")
            fi
        fi
    done

    if [ ${#missing_commands[@]} -gt 0 ]; then
        echo "Error: Comandos necesarios no encontrados: ${missing_commands[*]}" >&2
        return 1
    fi
    return 0
}

# Instala Yay desde AUR si no está presente
install_yay() {
    echo "Comando 'yay' no encontrado. Intentando instalarlo desde AUR."
    echo "Esto requiere 'git' y el grupo de paquetes 'base-devel'."

    local confirm_yay_install="N"
    local yay_install_confirmed=false

    if command -v dialog &> /dev/null; then
        if dialog --yesno "Yay no está instalado. ¿Quieres instalarlo ahora desde AUR?\n\nEsto requiere 'git' y el grupo de paquetes 'base-devel'." 10 60 2>&1 >/dev/tty; then
            confirm_yay_install="S"
            yay_install_confirmed=true
        else
            echo "Instalación de Yay omitida por el usuario." >&2
            return 1
        fi
    else
        echo "'dialog' no encontrado. Usando prompt de texto para solicitar confirmación de instalación de Yay."
        read -p "¿Quieres instalar Yay ahora? (S/n): " text_confirm_yay_install
        confirm_yay_install=${text_confirm_yay_install:-n}
    fi

    if [ "$yay_install_confirmed" = true ] || [[ "$confirm_yay_install" =~ ^[Ss]$ ]]; then
        echo "Confirmación recibida: Sí."
        if ! command -v git &> /dev/null || ! command -v makepkg &> /dev/null; then
            echo "Error: Comandos 'git' o 'makepkg' no encontrados. No se puede instalar Yay." >&2
            return 1
        fi

        local yay_dir="yay-bin"
        local yay_aur_url="https://aur.archlinux.org/${yay_dir}.git"

        echo "Clonando $yay_aur_url..."
        if git clone "$yay_aur_url"; then
            cd "$yay_dir" || { echo "Error: No se puede entrar al directorio $yay_dir"; rm -rf "$yay_dir"; return 1; }
            if makepkg -si; then
                echo "Yay instalado exitosamente."
                cd .. 
                rm -rf "$yay_dir"
                return 0
            else
                echo "Error durante la ejecución de makepkg -si para Yay." >&2
                cd .. 
                rm -rf "$yay_dir"
                return 1
            fi
        else
            echo "Error clonando el repositorio AUR de Yay." >&2
            return 1
        fi
    else
        echo "Instalación de Yay omitida por el usuario." >&2
        return 1
    fi
}

# --- Lógica de Creación del Script de Instalación ---
generate_install_script() {
    echo "Generando listas de paquetes..."

    local temp_all_installed="all_installed_packages.temp"
    local temp_official_repos="official_repos_packages.temp"
    local temp_pacman_list="pacman_packages.temp"
    local temp_yay_list="yay_packages.temp"

    # Limpia archivos temporales si ya existen
    if [ -f "$temp_all_installed" ] || [ -f "$temp_official_repos" ]; then
        echo "Archivos temporales ya existen. Limpiando..." >&2
        rm -f "$temp_all_installed" "$temp_official_repos" "$temp_pacman_list" "$temp_yay_list"
    fi

    trap "rm -f $temp_all_installed $temp_official_repos $temp_pacman_list $temp_yay_list" EXIT ERR

    echo "Obteniendo lista de paquetes instalados explícitamente (pacman -Qqe)..."
    if ! pacman -Qqe > "$temp_all_installed"; then
        echo "Error: No se pudo obtener lista de paquetes instalados explícitamente" >&2
        return 1
    fi

    echo "Obteniendo lista de paquetes en repositorios oficiales (pacman -Slq)..."
    if ! pacman -Slq > "$temp_official_repos"; then
        echo "Error: No se pudo obtener lista de paquetes de repos oficiales" >&2
        return 1
    fi

    echo "Separando paquetes de Pacman y Yay..."
    grep -Fxf "$temp_official_repos" "$temp_all_installed" > "$temp_pacman_list"
    grep -Fvxf "$temp_official_repos" "$temp_all_installed" > "$temp_yay_list"

    local pacman_list_content
    pacman_list_content=$(cat "$temp_pacman_list" || :)
    local yay_list_content
    yay_list_content=$(cat "$temp_yay_list" || :)

    cat << 'EOF_INSTALL_SCRIPT_HEADER' > "$INSTALL_SCRIPT_NAME"
#!/bin/bash
set -e
# Script generado automáticamente
EOF_INSTALL_SCRIPT_HEADER

    echo "$pacman_list_content" >> "$INSTALL_SCRIPT_NAME"
    echo "$yay_list_content" >> "$INSTALL_SCRIPT_NAME"

    echo "Script de instalación '$INSTALL_SCRIPT_NAME' generado exitosamente."
    return 0
}

# --- Lógica Principal del Generador ---
show_help() {
    echo "Uso: $0 [create]"
    echo "  Si se ejecuta sin argumentos: Genera el script de instalación."
    echo "  create: Realiza la misma acción."
}

if [ "$#" -eq 0 ] || [ "$1" = "create" ]; then
    if ! generate_install_script; then
        echo "La generación del script de instalación falló." >&2
        exit 1
    fi
else
    show_help
    exit 1
fi

exit 0
# ==============================================================================
