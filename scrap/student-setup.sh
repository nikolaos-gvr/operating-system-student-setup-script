#!/bin/sh

# =======================================================
# Student Work Environment Setup Script
# -------------------------------------------------------
# Purpose: Detects the operating system, updates it, adds
# repositories, upgrades packages, and installs software
# Compatible with Fedora, Arch, Linux Mint/Ubuntu, Haiku, FreeBSD
# =======================================================

# Exit immediately if any command fails. This is important so
# that we don't continue running commands if something goes wrong.
set -e

# Send all output (both normal messages and errors) to the terminal
# AND to a file called "student-setup.log" so we have a record of what happened.
exec > >(tee -i student-setup.log) 2>&1

# Just a visual separator to make the log easier to read
echo "======================================================"
echo "Detecting operating system..."
echo "======================================================"

# ----------------------------
# Step 0: Initialize variables
# ----------------------------
OS=""          # This variable will store the OS we detect
SUDO=""        # This variable will store "sudo" if the current user is not root

# Check if the script is run as root
# - "$(id -u)" gets the current user's ID
# - Root user always has ID 0
# - If the ID is not 0, set SUDO="sudo" so privileged commands can run
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

# ----------------------------
# Step 1: Detect OS
# ----------------------------
# uname -s prints the kernel name (like Linux, Haiku, FreeBSD)
unameOut=$(uname -s)

# If it's Haiku, set OS variable accordingly
if [ "$unameOut" = "Haiku" ]; then
    OS="haiku"
else
    # For Linux systems, check if /etc/os-release exists
    # This file contains info about the distribution (Fedora, Arch, Mint, Ubuntu, etc.)
    if [ -f /etc/os-release ]; then
        # Source the file to read variables like ID
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
                # Unsupported Linux distribution
                echo "Unsupported Linux distribution: $ID"
                exit 1
                ;;
        esac
    else
        # Check for FreeBSD if not Linux
        case "$unameOut" in
            FreeBSD)
                OS="freebsd"
                ;;
            *)
                # Unsupported OS
                echo "Unable to detect OS: $unameOut"
                exit 1
                ;;
        esac
    fi
fi

# Show the detected OS in the terminal/log
echo "Detected OS: $OS"

# ----------------------------
# Step 2: OS-specific updates and repository setup
# ----------------------------
# This section handles upgrading the system and adding extra repositories if needed
case "$OS" in

    fedora)
        # ---------------------------------------------------
        # Initial system upgrade for safety (default repos only)
        # ---------------------------------------------------
        echo "Performing initial update of Fedora system..."
        $SUDO dnf upgrade --refresh -y

        # ---------------------------------------------------
        # Add extra repositories (RPM Fusion) for additional software
        # ---------------------------------------------------
        echo "Adding Fedora extra repositories (RPM Fusion)..."
        $SUDO dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        $SUDO dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

        # ---------------------------------------------------
        # Refresh package metadata and upgrade again (now includes new repos)
        # ---------------------------------------------------
        echo "Refreshing metadata and upgrading again..."
        $SUDO dnf makecache --refresh
        $SUDO dnf upgrade -y

        # Save the install command for later so we can install packages in a uniform way
        PM="$SUDO dnf install -y"
        ;;

    arch)
        echo "Performing initial system update for Arch..."
        $SUDO pacman -Syu --noconfirm  # Full system upgrade

        # Check if Paru (AUR helper) exists. If not, install it
        echo "Setting up Paru (AUR helper) if missing..."
        if ! command -v paru >/dev/null; then
            # Install necessary tools to build packages from AUR
            $SUDO pacman -S --needed --noconfirm git base-devel
            cd /tmp
            rm -rf paru
            git clone https://aur.archlinux.org/paru.git
            cd paru
            makepkg -si --noconfirm
        else
            echo "Paru is already installed."
        fi

        PM="$SUDO pacman -S --noconfirm"
        ;;

    mint)
        echo "Performing initial update for Linux Mint / Ubuntu..."
        $SUDO apt update          # Refresh package index
        $SUDO apt upgrade -y      # Upgrade system packages from default repos

        # ---------------------------------------------------
        # Add VSCodium repository for extra software
        # ---------------------------------------------------
        echo "Adding VSCodium repository..."
        wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
            | gpg --dearmor | $SUDO tee /usr/share/keyrings/vscodium-archive-keyring.gpg > /dev/null
        echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main' \
            | $SUDO tee /etc/apt/sources.list.d/vscodium.list

        # Refresh metadata again after adding new repo, then upgrade again
        echo "Refreshing metadata and upgrading again..."
        $SUDO apt update
        $SUDO apt upgrade -y

        PM="$SUDO apt install -y"
        ;;

    haiku)
        # Haiku has a single package manager index
        echo "Updating Haiku system..."
        pkgman update
        PM="pkgman install -y"
        ;;

    freebsd)
        echo "Updating FreeBSD system..."
        $SUDO pkg update
        $SUDO pkg upgrade -y
        PM="$SUDO pkg install -y"
        ;;

    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Repository setup and system update complete."

# ----------------------------
# Step 3: Define list of packages to install
# ----------------------------
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
    freebsd)
        PACKAGES="firefox libreoffice neovim vlc rhythmbox vim"
        ;;
esac

echo "Packages to install: $PACKAGES"

# ----------------------------
# Step 4: Install each package individually
# ----------------------------
# This is done in a loop so that we can see progress in the terminal/log
echo "Installing packages one by one..."
for pkg in $PACKAGES; do
    echo "Installing $pkg..."
    $PM "$pkg"
done

echo "======================================================"
echo "All packages installed successfully."
echo "Script completed."
echo "======================================================"
