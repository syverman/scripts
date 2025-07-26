#!/bin/bash

# Script to install applications using yay on Arch Linux

# List of applications to install
packages=(
    7zip
    bat
    catppuccin-gtk-theme-mocha
    file-roller
    galculator
    ghostscript
    gparted
    grim
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
    hyprlock
    hyprpicker
    hyprprop-git
    hyprutils
    kitty
    lazygit
    nwg-look
    papirus-icon-theme
    qogir-cursor-theme
    rofi
    sddm
    starship
    stow
    swww
    tela-circle-icon-theme-nord
    thorium-browser-bin
    thunar-archive-plugin
    thunar-media-tags-plugin
    thunar-volman
    tldr
    trash-cli
    ttf-font-awesome
    ttf-hack-nerd
    ttf-iosevka-nerd
    ttf-iosevkaterm-nerd
    ttf-jetbrains-mono-nerd
    ttf-liberation
    ttf-meslo-nerd
    tumbler
    tumbler-extra-thumbnailers
    waypaper
    wl-color-picker
    wlogout
    xdg-desktop-portal-hyprland
    yad
    yazi
    zenity
    zinit
    zoxide
    aylurs-gtk-shell-git
    libgtop
    dart-sass
    wl-clipboard
    upower
    gtksourceview3
    libsoup3
    hyprpanel
)

echo "Starting installation of ${#packages[@]} packages using yay..."
echo "WARNING: Using --noconfirm. Review the package list carefully before running."

# Install packages using yay with --noconfirm
yay -S --noconfirm "${packages[@]}"

if [ $? -eq 0 ]; then
    echo "Installation completed successfully."
else
    echo "Installation finished, but some packages may have failed to install."
fi

echo "Please review the output above for any errors or warnings."