#!/bin/sh

set -e

echo "Installing NVIDIA drivers and Vulkan support has been disabled so please do it at your own risk"

#pacman -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader

echo "Installing gaming platforms and tools..."

pacman -S --needed --noconfirm steam lutris wine winetricks retroarch gamemode mangohud gamescope

echo "Installing AUR gaming tools..."

USER_NAME=${SUDO_USER:-$(logname)}

runuser -u "$USER_NAME" -- sh <<'EOF'
yay -S --needed --noconfirm heroic-games-launcher-bin
EOF

echo "Gaming environment installation complete."
