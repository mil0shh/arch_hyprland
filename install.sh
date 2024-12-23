#!/bin/bash

# Directory containing the package lists
LIST_DIR="list"

# File names for package lists
PACMAN_LIST="$LIST_DIR/pacman.list"
YAY_LIST="$LIST_DIR/yay.list"
GIT_LIST="$LIST_DIR/git.list"
PIPX_LIST="$LIST_DIR/pipx.list"

# Ensure the list directory exists
if [[ ! -d "$LIST_DIR" ]]; then
    echo "Error: Directory '$LIST_DIR' not found!"
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

# Function to clone git repositories
clone_git_repositories() {
    if [[ -f "$GIT_LIST" ]]; then
        echo "Cloning repositories from '$GIT_LIST' into /opt..."
        sudo mkdir -p /opt
        sudo chown "$USER" /opt
        while IFS= read -r repo; do
            if [[ -n "$repo" && "$repo" != \#* ]]; then
                echo "Cloning: $repo"
                git clone "$repo" /opt/$(basename "$repo" .git)
            fi
        done < "$GIT_LIST"
    else
        echo "File '$GIT_LIST' not found. Skipping git repositories."
    fi
}

# Function to install packages using pipx
install_pipx_packages() {
    if [[ -f "$PIPX_LIST" ]]; then
        echo "Installing packages from '$PIPX_LIST' using pipx..."
        if ! command -v pipx &>/dev/null; then
            echo "Installing pipx..."
            python3 -m pip install --user pipx
            python3 -m pipx ensurepath
        fi
        while IFS= read -r package; do
            if [[ -n "$package" && "$package" != \#* ]]; then
                echo "Installing: $package (pipx)"
                pipx install "$package"
            fi
        done < "$PIPX_LIST"
    else
        echo "File '$PIPX_LIST' not found. Skipping pipx packages."
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

# Install packages and repositories
install_pacman_packages
install_yay_packages
clone_git_repositories
install_pipx_packages

echo "All packages and repositories installed successfully!"
