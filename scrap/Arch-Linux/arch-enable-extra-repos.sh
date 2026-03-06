#!/bin/sh
# Arch Linux setup: enable multilib repo and install paru (AUR helper)

# Ensure running as root for pacman operations
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    echo "Please run: sudo sh $0"
    exit 1
fi

# 1) Enable multilib repo if not already enabled
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    echo "[multilib]" >> /etc/pacman.conf
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
    echo "Multilib repo enabled. Updating package database..."
    pacman -Sy
else
    echo "Multilib repository already enabled. Nothing to do here."
fi

# 2) Install paru (AUR helper)
# Paru must be built as a non-root user
REAL_USER=$(logname 2>/dev/null || echo "$SUDO_USER")
if ! command -v paru >/dev/null 2>&1; then
    echo "Paru is not installed. Installing paru from AUR..."

    # Install base-devel if missing
    pacman -Sy --needed --noconfirm base-devel git

    # Build and install paru as the real user
    su - "$REAL_USER" -c '
        cd /tmp || exit 1
        if [ ! -d paru ]; then
            echo "Cloning paru AUR repository..."
            git clone https://aur.archlinux.org/paru.git || exit 1
        else
            echo "paru repo already exists in /tmp. Pulling latest changes..."
            cd paru && git pull || exit 1
        fi
        cd paru || exit 1
        echo "Building and installing paru..."
        makepkg -si --noconfirm || exit 1
    '
    echo "Paru installation completed."
else
    echo "Paru is already installed. Nothing to do here."
fi

echo "Arch setup complete."