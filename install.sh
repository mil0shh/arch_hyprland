#!/bin/bash

# Directory containing the package lists
PACKAGES_DIR="list"

# File names for package lists
PACMAN_LIST="$PACKAGES_DIR/pacman.list"
YAY_LIST="$PACKAGES_DIR/yay.list"

# Ensure the package directory exists
if [[ ! -d "$PACKAGES_DIR" ]]; then
    echo "Error: Directory '$PACKAGES_DIR' not found!"
    exit 1
fi

# Function to install packages using pacman
install_pacman_packages() {
    if [[ -f "$PACMAN_LIST" ]]; then
        echo "Installing packages from '$PACMAN_LIST' using pacman..."
        while IFS= read -r package; do
            if [[ -n "$package" && "$package" != \#* ]]; then
                echo "Installing: $package (pacman)"
                sudo pacman -S --needed --noconfirm "$package"
            fi
        done < "$PACMAN_LIST"
    else
        echo "File '$PACMAN_LIST' not found. Skipping pacman packages."
    fi
}

# Function to install packages using yay
install_yay_packages() {
    if [[ -f "$YAY_LIST" ]]; then
        echo "Updating yay package database..."
        yay -Syu --noconfirm

        echo "Installing packages from '$YAY_LIST' using yay..."
        while IFS= read -r package; do
            if [[ -n "$package" && "$package" != \#* ]]; then
                echo "Installing: $package (yay)"
                yay -S --noconfirm "$package"
            fi
        done < "$YAY_LIST"
    else
        echo "File '$YAY_LIST' not found. Skipping yay packages."
    fi
}

# Update the system and install base-devel and yay if needed
echo "Updating the system with pacman..."
sudo pacman -Syu --noconfirm

if ! command -v yay &>/dev/null; then
    echo "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si --noconfirm
    cd .. && rm -rf yay
fi

# Install packages from both lists
install_pacman_packages
install_yay_packages

echo "All packages installed successfully!"
