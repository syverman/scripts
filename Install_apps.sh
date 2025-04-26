#!/bin/bash

# Script to install applications using yay on Arch Linux

# List of applications to install
packages=(
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