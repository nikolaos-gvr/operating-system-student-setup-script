#!/bin/sh
# Arch Linux: NVIDIA GTX 1650 DKMS + PRIME setup (modern method, no Bumblebee)

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    echo "Please run: sudo sh $0"
    exit 1
fi

echo "Updating package database..."
pacman -Sy --noconfirm

# Install NVIDIA DKMS drivers and utilities
NVIDIA_PACKAGES="
nvidia-dkms
nvidia-utils
lib32-nvidia-utils
nvidia-settings
xorg-xrandr
mesa
mesa-vdpau
"

echo "Installing NVIDIA DKMS and utilities..."
for pkg in $NVIDIA_PACKAGES; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
        echo "$pkg is already installed. Skipping."
    else
        echo "Installing $pkg..."
        pacman -S --noconfirm "$pkg"
    fi
done

# Enable NVIDIA modesetting for PRIME
# This sets kernel parameter nvidia-drm.modeset=1
GRUB_CFG="/etc/default/grub"
if ! grep -q "nvidia-drm.modeset=1" "$GRUB_CFG"; then
    echo "Adding NVIDIA DRM modeset to kernel parameters..."
    sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 nvidia-drm.modeset=1"/' "$GRUB_CFG"
    echo "Regenerating GRUB configuration..."
    if [ -f /boot/grub/grub.cfg ]; then
        grub-mkconfig -o /boot/grub/grub.cfg
    elif [ -d /boot/efi ]; then
        grub-mkconfig -o /boot/efi/grub/grub.cfg
    else
        echo "Could not detect GRUB config path. Please update GRUB manually."
    fi
else
    echo "NVIDIA DRM modeset kernel parameter already set. Nothing to do."
fi

# Enable nvidia modules
if ! lsmod | grep -q nvidia; then
    echo "Loading NVIDIA kernel modules..."
    modprobe nvidia
    modprobe nvidia_modeset
    modprobe nvidia_uvm
    modprobe nvidia_drm
else
    echo "NVIDIA kernel modules already loaded."
fi

# Create prime-run wrapper if not exists
PRIME_RUN="/usr/local/bin/prime-run"
if [ ! -f "$PRIME_RUN" ]; then
    echo "Creating prime-run wrapper..."
    cat << 'EOF' > "$PRIME_RUN"
#!/bin/sh
# Launch applications on NVIDIA GPU
__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
exec "$@"
EOF
    chmod +x "$PRIME_RUN"
else
    echo "prime-run already exists."
fi

echo "NVIDIA GTX 1650 + PRIME setup complete."
echo "Use: prime-run <application> to run apps on the NVIDIA GPU."