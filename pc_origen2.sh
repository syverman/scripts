#!/bin/bash

# =============================================================================
# ASCII Art: Jotace
# =============================================================================
cat << "EOF_ASCII_JOTACE"
  _           _
 | |         | |
 | | ___  ___| |_ ___  _ __   ___
 | |/ _ \/ __| __/ _ \| '_ \ / _ \
 | | (_) \__ \ || (_) | | | |  __/
 |_|\___/|___/\__\___/|_| |_|\___|

EOF_ASCII_JOTACE
# =============================================================================
# Script: pc_origen.sh (Nota: Nombre interno, el archivo es pc_origen2.sh)
# Descripción: Este script es un GENERADOR de un script de instalación.
# Función: Su propósito principal es crear un archivo llamado
#          'jotace_arch.sh' en la máquina de origen. Este script generado
#          contiene las listas de todos los paquetes instalados explícitamente
#          (tanto de Pacman como de Yay/AUR) de la máquina actual.
#          El script generado 'jotace_arch.sh' puede ser copiado y
#          ejecutado en otras máquinas Arch-based para replicar la
#          instalación de aplicaciones, incluyendo la configuración de zsh
#          y la adición al grupo video.
#          El script generado usará prompts interactivos para las preguntas
#          de Sí/No controladas por el script (como la instalación de Yay):
#          primero interfaz de texto con botones (dialog), y finalmente
#          prompt de texto normal. Las interacciones de Pacman/Yay son
#          manejadas por ellos mismos.
# Uso: Ejecutar sin argumentos (./pc_origen2.sh) o con el argumento
#      'create' (./pc_origen2.sh create) para generar el script de
#      instalación.
# =============================================================================

# Nombre del archivo de salida para el script de instalación
INSTALL_SCRIPT_NAME="jotace_arch.sh"

# --- Funciones Auxiliares (incluidas en el script generado) ---

# Verifica si los comandos necesarios están disponibles
# Esta función se copiará al script de instalación.
check_commands() {
    local missing_commands=()
    # Añadimos 'dialog' a la lista de comandos a verificar
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            # No consideramos dialog como un error fatal si falta
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
# Esta función se copiará al script de instalación.
install_yay() {
    echo "Comando 'yay' no encontrado. Intentando instalarlo desde AUR."
    echo "Esto requiere 'git' y el grupo de paquetes 'base-devel'."

    local confirm_yay_install="N" # Valor por defecto
    local yay_install_confirmed=false # Flag para saber si se confirmó via TUI

    # --- Intentar usar prompts interactivos ---

    # 1. Intentar usar dialog para el prompt TUI (terminal con botones)
    if command -v dialog &> /dev/null; then
        echo "Usando dialog para solicitar confirmación de instalación de Yay..."
        # dialog --yesno "text" height width
        # dialog retorna 0 para Yes, 1 para No, 255 para ESC
        if dialog --yesno "Yay no está instalado. ¿Quieres instalarlo ahora desde AUR?\n\nEsto requiere 'git' y el grupo de paquetes 'base-devel'." 10 60 2>&1 >/dev/tty; then
            confirm_yay_install="S" # Simular respuesta 'S' si dialog retorna 0
            yay_install_confirmed=true
        else
             # dialog retorna 1 para No, 255 para ESC. En ambos casos, no instalamos.
            echo "Confirmación recibida (dialog): No, o cancelado." >&2
            echo "Instalación de Yay omitida por el usuario." >&2
            return 1 # Salir de la función install_yay con fallo
        fi
    else
        # 2. Fallback a prompt de texto si dialog no está disponible
        echo "'dialog' no encontrado. Usando prompt de texto para solicitar confirmación de instalación de Yay."
        read -p "¿Quieres instalar Yay ahora? (s/N): " text_confirm_yay_install
        confirm_yay_install=${text_confirm_yay_install:-N} # Usar la respuesta del usuario o el valor por defecto
        # La confirmación se procesa en el siguiente bloque if
    fi

    # --- Procesar la confirmación (ya sea de dialog o prompt de texto) ---
    # Solo procedemos si la confirmación vino de dialog (yay_install_confirmed=true)
    # O si la respuesta del prompt de texto es 'S' o 's'
    if "$yay_install_confirmed" || [[ "$confirm_yay_install" =~ ^[Ss]$ ]]; then
        echo "Confirmación recibida: Sí."
        # Verificar comandos necesarios para la instalación de yay (git y makepkg)
        if ! command -v git &> /dev/null || ! command -v makepkg &> /dev/null; then
             echo "Error: Comandos 'git' o 'makepkg' no encontrados. No se puede instalar Yay." >&2
             echo "Asegúrate de que 'git' y el grupo 'base-devel' estén instalados." >&2
             return 1
        fi

        local yay_dir="yay-bin" # Usamos yay-bin para un binario precompilado
        local yay_aur_url="https://aur.archlinux.org/${yay_dir}.git"

        echo "Clonando $yay_aur_url..."
        if git clone "$yay_aur_url"; then
            echo "Clonación exitosa. Construyendo e instalando Yay..."
            echo "Se te pedirá la contraseña de sudo para 'makepkg -si'."
            cd "$yay_dir" || { echo "Error: No se puede entrar al directorio $yay_dir"; rm -rf "$yay_dir"; return 1; } # Añadido rm -rf en caso de fallo de cd

            # makepkg -si instala las dependencias y el paquete.
            # Requiere sudo internamente, makepkg lo solicitará.
            if makepkg -si; then
                echo "Yay instalado exitosamente."
                # Limpiar el directorio de origen
                cd ..
                echo "Limpiando el directorio $yay_dir..."
                rm -rf "$yay_dir"
                return 0 # Éxito
            else
                echo "Error durante la ejecución de makepkg -si para Yay." >&2
                cd .. # Salir del directorio antes de salir con error
                rm -rf "$yay_dir" # Intentar limpiar de todos modos
                return 1 # Fallo
            fi
        else
            echo "Error clonando el repositorio AUR de Yay." >&2
            return 1 # Fallo
        fi
    else
        # Esto solo se alcanzará si se usó el prompt de texto y la respuesta no fue S/s
        echo "Instalación de Yay omitida por el usuario." >&2
        return 1 # El usuario decidió no instalar
    fi
}


# --- Lógica de Creación del Script de Instalación ---
# Esta función contiene la lógica para generar el archivo jotace_arch.sh
generate_install_script() {
    echo "Generando listas de paquetes..." # Enviar mensajes informativos a stderr

    # Archivos temporales para la generación
    local temp_all_installed="all_installed_packages.temp"
    local temp_official_repos="official_repos_packages.temp"
    local temp_pacman_list="pacman_packages.temp"
    local temp_yay_list="yay_packages.temp"

    # Limpia archivos temporales si ya existen (Buena práctica)
    if [ -f "$temp_all_installed" ] || [ -f "$temp_official_repos" ]; then
        echo "Archivos temporales ya existen. Limpiando..." >&2
        rm -f "$temp_all_installed" "$temp_official_repos" "$temp_pacman_list" "$temp_yay_list"
    fi

    # Asegurarse de limpiar los archivos temporales al salir
    # Usamos trap con ERR para limpiar si algo falla antes de terminar
    trap "rm -f $temp_all_installed $temp_official_repos $temp_pacman_list $temp_yay_list" EXIT ERR

    # 1. Obtener todos los paquetes instalados explícitamente
    echo "Obteniendo lista de paquetes instalados explícitamente (pacman -Qqe)..."
    if ! pacman -Qqe > "$temp_all_installed"; then
        echo "Error listando paquetes instalados explícitamente." >&2
        return 1 # Indica fallo
    fi

    # 2. Obtener lista de paquetes en los repositorios oficiales síncronos
    echo "Obteniendo lista de paquetes en repositorios oficiales (pacman -Slq)..."
    if ! pacman -Slq > "$temp_official_repos"; then
        echo "Error listando paquetes de repos oficiales." >&2
        return 1 # Indica fallo
    fi

    echo "Separando paquetes de Pacman y Yay..."
    # Paquetes en repos oficiales que también están instalados explícitamente (Son paquetes de Pacman)
    grep -Fxf "$temp_official_repos" "$temp_all_installed" > "$temp_pacman_list"

    # Paquetes NO en repos oficiales que están instalados explícitamente (Probablemente son paquetes de Yay/AUR)
    grep -Fvxf "$temp_official_repos" "$temp_all_installed" > "$temp_yay_list"

    # Leer el contenido de los archivos temporales en variables
    local pacman_list_content
    # Usamos '|| :' para evitar que 'set -e' (si estuviera activo) falle si el archivo está vacío
    pacman_list_content=$(cat "$temp_pacman_list" || :)

    local yay_list_content
    yay_list_content=$(cat "$temp_yay_list" || :)

    # --- Escribir el contenido del script de instalación directamente al archivo ---
    # Usamos cat << 'EOF' ... EOF > "$INSTALL_SCRIPT_NAME" para redirigir todo el bloque.
    # La primera 'EOF_INSTALL_SCRIPT_HEADER' está entre comillas simples para evitar la expansión de variables aquí.

    cat << 'EOF_INSTALL_SCRIPT_HEADER' > "$INSTALL_SCRIPT_NAME"
#!/bin/bash

# =============================================================================
# Script: jotace_arch.sh
# Descripción: Este script es un INSTALADOR de aplicaciones y configuraciones.
# Función: Su propósito es instalar en la máquina actual los paquetes de
#          Pacman y Yay/AUR que fueron listados en la máquina de origen
#          cuando se ejecutó el script generador 'pc_origen.sh'.
#          También configura el shell del usuario a zsh (si era bash o fish)
#          y añade al usuario al grupo 'video'.
#          Omite automáticamente los paquetes que ya están instalados
#          y solicita confirmación para la instalación y dependencias.
#          Usa 'dialog' para prompts interactivos si está disponible.
# Uso: Ejecutar como tu usuario normal (no root): ./jotace_arch.sh
# =============================================================================

# Salir inmediatamente si un comando falla.
set -e

# --- Funciones Auxiliares (copiadas del generador) ---

# Verifica si los comandos necesarios están disponibles
check_commands() {
    local missing_commands=()
    # Añadimos 'dialog' a la lista de comandos a verificar
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            # No consideramos dialog como un error fatal si falta
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

    # 1. Intentar usar dialog para el prompt TUI (terminal con botones)
    if command -v dialog &> /dev/null; then
        echo "Usando dialog para solicitar confirmación de instalación de Yay..."
        # dialog --yesno "text" height width
        # dialog retorna 0 para Yes, 1 para No, 255 para ESC
        if dialog --yesno "Yay no está instalado. ¿Quieres instalarlo ahora desde AUR?\n\nEsto requiere 'git' y el grupo de paquetes 'base-devel'." 10 60 2>&1 >/dev/tty; then
            confirm_yay_install="S" # Simular respuesta 'S' si dialog retorna 0
            yay_install_confirmed=true
        else
             # dialog retorna 1 para No, 255 para ESC. En ambos casos, no instalamos.
            echo "Confirmación recibida (dialog): No, o cancelado." >&2
            echo "Instalación de Yay omitida por el usuario." >&2
            return 1 # Salir de la función install_yay con fallo
        fi
    else
        # 2. Fallback a prompt de texto si dialog no está disponible
        echo "'dialog' no encontrado. Usando prompt de texto para solicitar confirmación de instalación de Yay."
        read -p "¿Quieres instalar Yay ahora? (s/N): " text_confirm_yay_install
        confirm_yay_install=${text_confirm_yay_install:-N} # Usar la respuesta del usuario o el valor por defecto
        # La confirmación se procesa en el siguiente bloque if
    fi

    # --- Procesar la confirmación (ya sea de dialog o prompt de texto) ---
    # Solo procedemos si la confirmación vino de dialog (yay_install_confirmed=true)
    # O si la respuesta del prompt de texto es 'S' o 's'
    if "$yay_install_confirmed" || [[ "$confirm_yay_install" =~ ^[Ss]$ ]]; then
        echo "Confirmación recibida: Sí."
        # Verificar comandos necesarios para la instalación de yay (git y makepkg)
        if ! command -v git &> /dev/null || ! command -v makepkg &> /dev/null; then
             echo "Error: Comandos 'git' o 'makepkg' no encontrados. No se puede instalar Yay." >&2
             echo "Asegúrate de que 'git' y el grupo 'base-devel' estén instalados." >&2
             return 1
        fi

        local yay_dir="yay-bin" # Usamos yay-bin para un binario precompilado
        local yay_aur_url="https://aur.archlinux.org/${yay_dir}.git"

        echo "Clonando $yay_aur_url..."
        if git clone "$yay_aur_url"; then
            echo "Clonación exitosa. Construyendo e instalando Yay..."
            echo "Se te pedirá la contraseña de sudo para 'makepkg -si'."
            cd "$yay_dir" || { echo "Error: No se puede entrar al directorio $yay_dir"; rm -rf "$yay_dir"; return 1; } # Añadido rm -rf en caso de fallo de cd

            # makepkg -si instala las dependencias y el paquete.
            # Requiere sudo internamente, makepkg lo solicitará.
            if makepkg -si; then
                echo "Yay instalado exitosamente."
                # Limpiar el directorio de origen
                cd ..
                echo "Limpiando el directorio $yay_dir..."
                rm -rf "$yay_dir"
                return 0 # Éxito
            else
                echo "Error durante la ejecución de makepkg -si para Yay." >&2
                cd .. # Salir del directorio antes de salir con error
                rm -rf "$yay_dir" # Intentar limpiar de todos modos
                return 1 # Fallo
            fi
        else
            echo "Error clonando el repositorio AUR de Yay." >&2
            return 1 # Fallo
        fi
    else
        # Esto solo se alcanzará si se usó el prompt de texto y la respuesta no fue S/s
        echo "Instalación de Yay omitida por el usuario." >&2
        return 1 # El usuario decidió no instalar
    fi
}

# --- Listas de Paquetes Incrustadas ---
# Estas listas fueron generadas en la máquina de origen por pc_origen.sh.

# Pacman packages list
read -r -d '' PACMAN_PACKAGES_LIST << 'EOF_PACMAN_LIST'
EOF_INSTALL_SCRIPT_HEADER

    # Insertar el contenido real de la lista de Pacman aquí.
    # No usamos comillas dobles para permitir que las líneas vacías se incluyan si las hay.
    echo "$pacman_list_content" >> "$INSTALL_SCRIPT_NAME" # Redirigir al archivo

    cat << 'EOF_INSTALL_SCRIPT_YAY_SECTION' >> "$INSTALL_SCRIPT_NAME" # Redirigir al archivo
EOF_PACMAN_LIST

# Yay/AUR packages list
read -r -d '' YAY_PACKAGES_LIST << 'EOF_YAY_LIST'
EOF_INSTALL_SCRIPT_YAY_SECTION

    # Insertar el contenido real de la lista de Yay aquí.
    echo "$yay_list_content" >> "$INSTALL_SCRIPT_NAME" # Redirigir al archivo

    cat << 'EOF_INSTALL_SCRIPT_FOOTER' >> "$INSTALL_SCRIPT_NAME" # Redirigir al archivo
EOF_YAY_LIST

# --- Lógica Principal de Instalación ---

echo "Iniciando proceso de instalación de paquetes desde listas incrustadas..."
echo "Los paquetes que ya estén instalados serán omitidos (--needed)."
echo "Se te solicitará confirmación para la instalación y dependencias."
echo "Las preguntas de Sí/No controladas por este script usarán 'dialog' (con botones en terminal) si está disponible, de lo contrario, usarán prompts de texto normales."
echo "Asegúrate de ejecutar este script como tu usuario normal (no root)."

# Verificar comandos necesarios al inicio del script de instalación
# No consideramos dialog como un error fatal si falta, ya que hay fallback
if ! check_commands pacman git makepkg getent chsh usermod whoami; then
    echo "Faltan comandos esenciales. Por favor, asegúrate de que pacman, git, makepkg, getent, chsh, usermod y whoami estén instalados." >&2
    exit 1
fi


# Instalar paquetes de Pacman primero
# -s: chequea y resuelve dependencias
# -y: sincroniza la base de datos de paquetes
# -u: actualiza paquetes
# --needed: no reinstala un paquete si ya está instalado y actualizado
# -: lee los nombres de los paquetes de la entrada estándar
# Eliminamos líneas vacías antes de pasar a pacman para evitar errores si la lista tiene saltos de línea al final
if [ -n "$PACMAN_PACKAGES_LIST" ]; then # Verifica si la variable no está vacía
    echo ""
    echo "--- Instalando paquetes de Pacman ---"
    echo "Se te pedirá la contraseña de sudo para pacman -Syu."
    echo "Pacman solicitará confirmación para la instalación y dependencias."
    # Usamos grep -v '^$' para eliminar cualquier línea vacía
    if echo "$PACMAN_PACKAGES_LIST" | grep -v '^$' | sudo pacman -Syu --needed -; then
        echo "--- Paquetes de Pacman instalados exitosamente ---"
    else
        echo "--- Error instalando paquetes de Pacman ---" >&2
        echo "Continuando con paquetes de Yay/AUR si los hay..."
    fi
else
    echo "No hay paquetes de Pacman en la lista incrustada. Saltando instalación de Pacman."
fi

# Instalar paquetes de Yay/AUR
# yay -S: instala paquetes
# --needed: no reinstala si ya está instalado
# -: lee los nombres de los paquetes de la entrada estándar
# Eliminamos líneas vacías antes de pasar a yay
if [ -n "$YAY_PACKAGES_LIST" ]; then # Verifica si la variable no está vacía
    echo ""
    echo "--- Instalando paquetes de Yay/AUR ---"
    # Verificar si yay está instalado, instalar si no
    if ! command -v yay &> /dev/null; then
        echo "Comando 'yay' no encontrado."
        # La función install_yay maneja el prompt (TUI o texto) y la instalación
        if ! install_yay; then
            echo "No se pudieron instalar los paquetes de Yay/AUR porque la instalación de Yay falló o fue omitida." >&2
            # No salimos aquí, continuamos con las configuraciones adicionales si es posible
        else
             # Si install_yay tuvo éxito, yay ya está disponible, ahora instalamos los paquetes de la lista
             echo "Yay instalado. Procediendo a instalar paquetes de Yay/AUR desde la lista."
             echo "Ejecutando 'yay -S --needed'. Yay solicitará confirmación para la instalación y dependencias."
             # Usamos grep -v '^$' para eliminar cualquier línea vacía
             if echo "$YAY_PACKAGES_LIST" | grep -v '^$' | yay -S --needed -; then
                  echo "--- Paquetes de Yay/AUR instalados exitosamente ---"
             else
                  echo "--- Error instalando paquetes de Yay/AUR ---" >&2
                  # Decide si quieres salir o solo reportar.
             fi
        fi
    else
        # Yay ya estaba instalado, procedemos directamente a instalar los paquetes de la lista
        echo "Comando 'yay' encontrado. Procediendo a instalar paquetes de Yay/AUR desde la lista."
        echo "Ejecutando 'yay -S --needed'. Yay solicitará confirmación para la instalación y dependencias."
        # Usamos grep -v '^$' para eliminar cualquier línea vacía
        if echo "$YAY_PACKAGES_LIST" | grep -v '^$' | yay -S --needed -; then
             echo "--- Paquetes de Yay/AUR instalados exitosamente ---"
        else
             echo "--- Error instalando paquetes de Yay/AUR ---" >&2
             # Decide si quieres salir o solo reportar.
        fi
    fi
else
    echo "No hay paquetes de Yay/AUR en la lista incrustada. Saltando instalación de Yay."
fi


# --- Configuraciones Adicionales ---

echo ""
echo "--- Realizando configuraciones adicionales (shell y grupo de usuario) ---"

# Obtener el nombre del usuario actual (el que ejecuta el script)
CURRENT_USER=$(whoami)

# Verificar si el usuario actual no es root
if [ "$CURRENT_USER" = "root" ]; then
    echo "Error: Este script de instalación debe ejecutarse como un usuario normal, no como root." >&2
    echo "No se realizarán las configuraciones de shell y grupo para evitar problemas." >&2
else
    echo "Usuario actual detectado: $CURRENT_USER"

    # 1. Cambiar shell a zsh si es bash o fish
    # Primero, asegurarnos de que zsh esté instalado.
    if ! command -v zsh &> /dev/null; then
        echo "El comando 'zsh' no fue encontrado. Intentando instalarlo con Pacman."
        # Añadimos zsh a la lista de pacman para instalarlo si no está
        if echo "zsh" | sudo pacman -S --needed -; then
            echo "'zsh' instalado exitosamente."
        else
            echo "Error: No se pudo instalar 'zsh'. No se cambiará el shell." >&2
        fi
    fi

    # Si zsh está ahora disponible, intentamos cambiar el shell
    if command -v zsh &> /dev/null; then
        CURRENT_SHELL=$(getent passwd "$CURRENT_USER" | cut -d: -f7)
        echo "Shell actual de $CURRENT_USER: $CURRENT_SHELL"

        if [[ "$CURRENT_SHELL" == */bash ]] || [[ "$CURRENT_SHELL" == */fish ]]; then
            echo "Cambiando shell de $CURRENT_USER a zsh..."
            # chsh -s /path/to/zsh username
            # Necesita sudo y la contraseña del usuario
            if sudo chsh -s "$(command -v zsh)" "$CURRENT_USER"; then
                echo "Shell de $CURRENT_USER cambiado a zsh exitosamente. El cambio surtirá efecto en la próxima sesión."
            else
                echo "Error: No se pudo cambiar el shell de $CURRENT_USER a zsh con chsh." >&2
                echo "Es posible que necesites hacerlo manualmente con 'chsh -s /usr/bin/zsh' como tu usuario." >&2
            fi
        else
            echo "El shell de $CURRENT_USER no es bash ni fish ($CURRENT_SHELL). No se realizará el cambio a zsh."
        fi
    else
        echo "No se pudo cambiar el shell a zsh porque el comando 'zsh' no está disponible." >&2
    fi

    echo "" # Espacio antes de la siguiente acción

    # 2. Añadir usuario al grupo video
    # Verificar si el grupo video existe
    if getent group video &> /dev/null; then
        echo "Añadiendo usuario $CURRENT_USER al grupo 'video'..."
        # usermod -aG groupname username
        # Necesita sudo
        if sudo usermod -aG video "$CURRENT_USER"; then
            echo "Usuario $CURRENT_USER añadido al grupo 'video' exitosamente. Es posible que necesites cerrar sesión y volver a iniciarla para que el cambio surta efecto."
        else
            echo "Error: No se pudo añadir al usuario $CURRENT_USER al grupo 'video' con usermod." >&2
        fi
    else
        echo "El grupo 'video' no existe en este sistema. No se añadirá al usuario." >&2 # Corregido >2 a >&2
    fi

fi # Fin de la verificación si el usuario no es root

echo ""
echo "Proceso de instalación y configuración finalizado."

exit 0
EOF_INSTALL_SCRIPT_FOOTER

    echo "Script de instalación '$INSTALL_SCRIPT_NAME' generado exitosamente en el directorio actual."
    echo "Ahora puedes copiar '$INSTALL_SCRIPT_NAME' a tu máquina de destino."
    return 0 # Indica que la generación fue exitosa
}


# --- Lógica Principal del Generador ---

# Muestra el mensaje de uso del script principal
show_help() {
    echo "Uso: $0 [create]"
    echo ""
    echo "  Si se ejecuta sin argumentos: Genera el script de instalación '$INSTALL_SCRIPT_NAME' en el directorio actual."
    echo "  create                      : Realiza la misma acción que ejecutar sin argumentos."
    echo ""
    echo "Este script generado contendrá las listas de paquetes de Pacman y Yay"
    echo "de la máquina actual, y configurará zsh y el grupo video."
    echo "El script de instalación usará prompts interactivos (de texto con botones si 'dialog' está disponible, o de texto normal si no)."
    echo ""
    echo "Ejemplo:"
    echo "  ./pc_origen2.sh" # O el nombre que le des al script
    echo "  # Opcional: ./pc_origen2.sh create"
    # Usamos el nombre real del script de instalación en el ejemplo
    echo "  # Luego copia '$INSTALL_SCRIPT_NAME' a la máquina de destino y ejecútalo allí:"
    echo "  # chmod +x $INSTALL_SCRIPT_NAME"
    echo "  # ./$INSTALL_SCRIPT_NAME"
}


# Verifica si no hay argumentos o si el argumento es 'create'
if [ "$#" -eq 0 ] || [ "$1" = "create" ]; then
    # Ejecuta la función para generar el script
    if ! generate_install_script; then
        echo "La generación del script de instalación falló." >&2
        exit 1
    fi
else
    # Si se proporciona un argumento diferente a 'create', muestra la ayuda
    show_help
    exit 1
fi

exit 0
# FIN DEL SCRIPT - Código duplicado eliminado
