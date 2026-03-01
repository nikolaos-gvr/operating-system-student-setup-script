#!/bin/sh

# =======================================================
# Multi-OS GRUB Setup Script
# -------------------------------------------------------
# Purpose: Ensures that multiple Linux installations
# (Fedora, Arch, Mint/Ubuntu) detect each other properly
# in GRUB after upgrades.
# =======================================================

# Exit immediately if any command fails
set -e

# Log all output to terminal and to multi-os-setup.log
exec > >(tee -i multi-os-setup.log) 2>&1

echo "======================================================"
echo "Multi-OS GRUB Setup Script"
echo "======================================================"

# ----------------------------
# Step 0: Detect OS
# ----------------------------
OS=""
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

unameOut=$(uname -s)

if [ "$unameOut" = "Linux" ]; then
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
        echo "Cannot detect Linux distribution."
        exit 1
    fi
else
    echo "Unsupported OS: $unameOut"
    exit 1
fi

echo "Detected OS: $OS"

# ----------------------------
# Step 1: Install os-prober
# ----------------------------
# os-prober detects other operating systems so GRUB can add them to the menu
case "$OS" in
    fedora)
        echo "Installing os-prober on Fedora..."
        $SUDO dnf install -y os-prober
        ;;
    arch)
        echo "Installing os-prober on Arch..."
        $SUDO pacman -S --noconfirm os-prober
        ;;
    mint)
        echo "Installing os-prober on Linux Mint / Ubuntu..."
        $SUDO apt install -y os-prober
        ;;
esac

# ----------------------------
# Step 2: Enable os-prober in GRUB
# ----------------------------
# New GRUB versions disable os-prober by default.
# Setting GRUB_DISABLE_OS_PROBER=false ensures all other OSes are detected
GRUB_DEFAULT_FILE="/etc/default/grub"

if [ -f "$GRUB_DEFAULT_FILE" ]; then
    if grep -q "GRUB_DISABLE_OS_PROBER=" "$GRUB_DEFAULT_FILE"; then
        # Replace existing line
        $SUDO sed -i 's/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$GRUB_DEFAULT_FILE"
    else
        # Add the line if it doesn't exist
        echo 'GRUB_DISABLE_OS_PROBER=false' | $SUDO tee -a "$GRUB_DEFAULT_FILE"
    fi
else
    echo "Warning: GRUB default file not found at $GRUB_DEFAULT_FILE. You may need to enable os-prober manually."
fi

# ----------------------------
# Step 3: Regenerate GRUB configuration
# ----------------------------
echo "Regenerating GRUB configuration..."

case "$OS" in
    fedora)
        # Fedora stores GRUB config in /boot/efi/EFI/fedora
        $SUDO grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
        ;;
    arch)
        $SUDO grub-mkconfig -o /boot/grub/grub.cfg
        ;;
    mint)
        $SUDO update-grub
        ;;
esac

echo "======================================================"
echo "Multi-OS GRUB setup complete. All other OSes should now appear in GRUB menu."
echo "======================================================"
