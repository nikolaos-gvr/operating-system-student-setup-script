#!/bin/sh

# =======================================================
# NVIDIA GPU Setup Script (Self-contained)
# -------------------------------------------------------
# Automatically sets up NVIDIA drivers, DKMS, 32-bit libs,
# CUDA toolkit, and PRIME GPU offloading on Arch, Fedora, or Mint/Ubuntu.
# Fully self-contained — enables all required repos/architectures.
# =======================================================

# Exit immediately if any command fails
set -e

# Redirect all output (normal + errors) to both terminal and log file
exec > >(tee -i nvidia-setup.log) 2>&1

echo "======================================================"
echo "Starting NVIDIA GPU setup..."
echo "======================================================"

# ----------------------------
# Step 0: Detect OS
# ----------------------------
# SUDO variable will be "sudo" if the script is not run as root
OS=""
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

# uname -s gives the kernel name, should be "Linux" here
unameOut=$(uname -s)

if [ "$unameOut" != "Linux" ]; then
    echo "Unsupported OS: $unameOut"
    exit 1
fi

# Check /etc/os-release to figure out which Linux distribution we are running
if [ -f /etc/os-release ]; then
    # Load variables like ID and VERSION_ID
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

echo "Detected OS: $OS"

# ----------------------------
# Step 1: Enable necessary repos / architectures
# ----------------------------
# This ensures the system can see packages like lib32, DKMS drivers, or CUDA
case "$OS" in

    arch)
        echo "Ensuring multilib is enabled for 32-bit libraries..."
        # Check if [multilib] exists in pacman.conf
        if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
            # Add [multilib] section
            echo "[multilib]" | $SUDO tee -a /etc/pacman.conf
            echo "Include = /etc/pacman.d/mirrorlist" | $SUDO tee -a /etc/pacman.conf
        fi
        echo "Refreshing package database..."
        $SUDO pacman -Sy
        ;;

    fedora)
        echo "Adding RPM Fusion repositories for NVIDIA and CUDA..."
        # Free and Nonfree repos needed for NVIDIA drivers and CUDA
        $SUDO dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        $SUDO dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        $SUDO dnf makecache --refresh
        ;;

    mint)
        echo "Enabling 32-bit (i386) architecture for Mint/Ubuntu..."
        # Some NVIDIA apps and lib32 support require i386 architecture
        $SUDO dpkg --add-architecture i386
        $SUDO apt update
        ;;
esac

# ----------------------------
# Step 2: Install prerequisites (headers, build tools, DKMS, lib32)
# ----------------------------
# These packages are needed to build NVIDIA modules and provide 32-bit library support
case "$OS" in

    arch)
        echo "Installing Arch prerequisites..."
        $SUDO pacman -S --needed --noconfirm linux-headers dkms base-devel lib32-glibc
        ;;

    fedora)
        echo "Installing Fedora prerequisites..."
        $SUDO dnf install -y kernel-headers kernel-devel dkms gcc make lib32-glibc
        ;;

    mint)
        echo "Installing Mint / Ubuntu prerequisites..."
        $SUDO apt install -y build-essential dkms linux-headers-$(uname -r) lib32gcc-s1
        ;;
esac

# ----------------------------
# Step 3: Install NVIDIA drivers + settings
# ----------------------------
# This installs the drivers, DKMS support, lib32 libraries, and NVIDIA GUI tool
case "$OS" in

    arch)
        echo "Installing NVIDIA drivers, DKMS, lib32 support, and settings..."
        $SUDO pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings
        ;;

    fedora)
        echo "Installing NVIDIA DKMS drivers, CUDA support, and settings..."
        $SUDO dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-settings
        ;;

    mint)
        echo "Installing NVIDIA drivers, DKMS, lib32 support, and settings..."
        $SUDO apt install -y nvidia-driver nvidia-dkms-$(uname -r) lib32-nvidia-glibc nvidia-settings
        ;;
esac

# ----------------------------
# Step 4: Setup PRIME GPU offloading
# ----------------------------
# Allows running individual apps on the NVIDIA GPU using 'prime-run'
echo "Setting up PRIME GPU offloading..."
case "$OS" in

    arch)
        # Arch does not provide a helper script, so we create one
        if [ ! -f /usr/local/bin/prime-run ]; then
            echo "Creating prime-run helper script..."
            $SUDO tee /usr/local/bin/prime-run >/dev/null << 'EOF'
#!/bin/sh
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only "$@"
EOF
            $SUDO chmod +x /usr/local/bin/prime-run
        fi
        echo "Use 'prime-run <app>' to run applications on discrete NVIDIA GPU."
        ;;

    fedora|mint)
        # Fedora and Mint drivers already include prime-run helper
        echo "PRIME support included with NVIDIA driver package. Use 'prime-run <app>' if available."
        ;;
esac

# ----------------------------
# Step 5: Install CUDA toolkit
# ----------------------------
# Needed for CS students / GPU programming
echo "Installing CUDA toolkit..."
case "$OS" in

    arch)
        $SUDO pacman -S --noconfirm cuda
        ;;

    fedora)
        $SUDO dnf install -y cuda
        ;;

    mint)
        $SUDO apt install -y nvidia-cuda-toolkit
        ;;
esac

# ----------------------------
# Step 6: Finished
# ----------------------------
echo "======================================================"
echo "NVIDIA GPU setup complete!"
echo "Verify installation with 'nvidia-smi'."
echo "Use 'prime-run <app>' to run apps on the NVIDIA GPU if supported."
echo "======================================================"
