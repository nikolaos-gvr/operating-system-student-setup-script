#!/bin/sh
# Arch Linux: install base set of everyday packages (non-gaming, non-GUI)

# Ensure running as root for pacman operations
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    echo "Please run: sudo sh $0"
    exit 1
fi

echo "Updating system package database..."
pacman -Sy --noconfirm

# List of base packages for everyday use
PACKAGES="
git
base-devel
linux-headers
vim
nano
htop
curl
wget
tar
unzip
zip
rsync
openssh
net-tools
sudo
bash-completion
"

echo "Installing base packages..."
for pkg in $PACKAGES; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
        echo "$pkg is already installed. Skipping."
    else
        echo "Installing $pkg..."
        pacman -S --noconfirm "$pkg"
    fi
done

echo "Base package installation complete."