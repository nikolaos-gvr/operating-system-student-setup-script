#!/bin/sh

# =======================================================
# Student Work Environment Setup Script (POSIX-compatible)
# Detects OS, sets up repos, updates system, installs packages
# Supports Fedora, Arch, Linux Mint, Haiku
# =======================================================

echo "Detecting operating system..."

OS=""

# ----------------------------
# Step 1: Detect OS
# ----------------------------
if [ "$(uname -s)" = "Haiku" ]; then
    # Haiku OS detected
    OS="haiku"
else
    # Detect Linux distributions via /etc/os-release
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            fedora)
                OS="fedora"
                ;;
            arch)
                OS="arch"
                ;;
            linuxmint|ubuntu)
                OS="mint"
                ;;
            *)
                echo "Unsupported Linux distribution: $ID"
                exit 1
                ;;
        esac
    else
        echo "Unable to detect OS."
        exit 1
    fi
fi

echo "Detected OS: $OS"

# ----------------------------
# Step 2: Distro-specific repository setup
# ----------------------------
case "$OS" in

    fedora)
        echo "Updating system and adding RPM Fusion repositories..."
        # Upgrade system to latest packages
        sudo dnf upgrade --refresh -y
        # Install free and nonfree RPM Fusion repos for extra software
        sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        ;;

    arch)
        echo "Updating system and installing Paru (AUR helper) for Arch..."
        # Update system packages
        sudo pacman -Syu --noconfirm
        # Install Paru only if not already installed
        if ! command -v paru >/dev/null 2>&1; then
            # Ensure base-devel and git are installed for building AUR packages
            sudo pacman -S --needed --noconfirm git base-devel
            cd /tmp
            git clone https://aur.archlinux.org/paru.git
            cd paru
            makepkg -si --noconfirm
        else
            echo "Paru is already installed."
        fi
        ;;

    mint)
        echo "Updating system and setting up VSCodium repository for Mint..."
        # Update package index and upgrade system
        sudo apt update
        sudo apt upgrade -y

        # Add VSCodium GPG key and repository
        wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
            | gpg --dearmor | sudo tee /usr/share/keyrings/vscodium-archive-keyring.gpg > /dev/null

        echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main' \
            | sudo tee /etc/apt/sources.list.d/vscodium.list

        # Update package index again after adding repo
        sudo apt update
        ;;

    haiku)
        echo "Updating system on Haiku..."
        # Update package index
        pkgman update
        ;;

esac

echo "Repository setup and system update complete."

# ----------------------------
# Step 3: Define package lists
# ----------------------------
# Assign the software to install depending on OS
PACKAGES=""

case "$OS" in
    fedora)
        PACKAGES="firefox libreoffice neovim vlc rhythmbox code"
        ;;

    arch)
        PACKAGES="firefox libreoffice-fresh neovim vlc rhythmbox code"
        ;;

    mint)
        PACKAGES="firefox libreoffice neovim vlc rhythmbox codium wget gpg"
        ;;

    haiku)
        PACKAGES="firefox libreoffice pe vlc vim"
        ;;
esac

echo "Packages to install: $PACKAGES"

# ----------------------------
# Step 4: Install packages
# ----------------------------
case "$OS" in

    fedora)
        sudo dnf install -y $PACKAGES
        ;;

    arch)
        sudo pacman -S --noconfirm $PACKAGES
        ;;

    mint)
        sudo apt install -y $PACKAGES
        ;;

    haiku)
        pkgman install $PACKAGES
        ;;

esac

echo "All packages installed successfully."
