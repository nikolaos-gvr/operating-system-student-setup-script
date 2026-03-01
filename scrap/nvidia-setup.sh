#!/bin/sh
#This is a setup script for post-install setup of Nvidia GPU drivers, it should detect distro or OS, install the needed packages and do the proper configuration for the intended system
#if any command fails, it will exit the script imediately
set -e
# Redirect all output (normal + errors) to both terminal and log file
exec > >(tee -i nvidia-setup.log) 2>&1
# ASCII Banner
cat <<'EOF'
     __        _     _ _             _      _                           _                               _       _   
  /\ \ \__   _(_) __| (_) __ _    __| |_ __(_)_   _____ _ __   ___  ___| |_ _   _ _ __    ___  ___ _ __(_)_ __ | |_ 
 /  \/ /\ \ / / |/ _` | |/ _` |  / _` | '__| \ \ / / _ \ '__| / __|/ _ \ __| | | | '_ \  / __|/ __| '__| | '_ \| __|
/ /\  /  \ V /| | (_| | | (_| | | (_| | |  | |\ V /  __/ |    \__ \  __/ |_| |_| | |_) | \__ \ (__| |  | | |_) | |_ 
\_\ \/    \_/ |_|\__,_|_|\__,_|  \__,_|_|  |_| \_/ \___|_|    |___/\___|\__|\__,_| .__/  |___/\___|_|  |_| .__/ \__|
                                                                                 |_|                     |_|        
EOF
echo "============================"
echo "Starting NVIDIA GPU setup..."
echo "============================"

# -----------------
# Step 0: Detect OS
# -----------------
#variable OS and SUDO, OS is the detected operating system, SUDO exists in case the script is not run as root, then concatenates it at the start of the command to run the rest of the script in root
OS=""
SUDO=""
#command that detects if you are root, if not root then puts "sudo" at the SUDO variable so the other commands run as SUDO
[ "$(id -u)" -ne 0 ] && SUDO="sudo"
#detection of the Linux Distro
unameOut=$(uname -s)
#if a Linux distro is not detected, then it shows that the OS is unsupported and exists the script
[ "$unameOut" != "Linux" ] && echo "Unsupported OS: $unameOut" && exit 1
#finds which spesific linux distro it is, to avoid the posibility of running the script in an unsupported distro (e.g. Gentoo)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        fedora) OS="fedora" ;;
        arch) OS="arch" ;;
        linuxmint|ubuntu) OS="mint" ;;
        *)
            echo "Unsupported Linux distribution: $ID"
            exit 1
            ;;
    esac
else
    #there is the posibility of the Linux Distro not being detected
    echo "Cannot detect Linux distribution."
    exit 1
fi
#shows which Linux Distro is detected
echo "Detected OS: $OS"
# Step 0.5: Detect existing NVIDIA drivers
echo "Checking for existing NVIDIA driver installation..."
#boolean value that starts at false, used for understanding if we should install nvidia drivers or no
DRIVER_INSTALLED=false
#checks which distro it is, then runs the cooresponding command if there is 
case "$OS" in
    arch)
        pacman -Q nvidia nvidia-dkms >/dev/null 2>&1 && DRIVER_INSTALLED=true
        ;;
    fedora)
        rpm -q akmod-nvidia xorg-x11-drv-nvidia >/dev/null 2>&1 && DRIVER_INSTALLED=true
        ;;
    mint)
        dpkg -l | grep -q '^ii.*nvidia-driver' && DRIVER_INSTALLED=true
        ;;
esac

if [ "$DRIVER_INSTALLED" = true ]; then
    echo
    echo "⚠️  NVIDIA drivers appear to already be installed."
    printf "Are you sure you want to continue and re-run this script? [y/N]: "
    read answer
    case "$answer" in
        y|Y|yes|YES)
            echo "Continuing with NVIDIA setup..."
            ;;
        *)
            echo "Aborting setup."
            exit 0
            ;;
    esac
fi

# ----------------------------
# Step 1: Enable necessary repos / architectures
# ----------------------------
case "$OS" in
    arch)
        echo "Ensuring multilib is enabled for 32-bit libraries..."
        if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
            echo "[multilib]" | $SUDO tee -a /etc/pacman.conf
            echo "Include = /etc/pacman.d/mirrorlist" | $SUDO tee -a /etc/pacman.conf
        fi
        $SUDO pacman -Sy
        ;;
    fedora)
        echo "Adding RPM Fusion repositories..."
        $SUDO dnf install -y \
            https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
            https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        $SUDO dnf makecache --refresh
        ;;
    mint)
        echo "Enabling i386 architecture..."
        $SUDO dpkg --add-architecture i386
        $SUDO apt update
        ;;
esac

# ----------------------------
# Step 2: Install prerequisites
# ----------------------------
case "$OS" in
    arch)
        $SUDO pacman -S --needed --noconfirm linux-headers dkms base-devel lib32-glibc
        ;;
    fedora)
        $SUDO dnf install -y kernel-headers kernel-devel dkms gcc make lib32-glibc
        ;;
    mint)
        $SUDO apt install -y build-essential dkms linux-headers-$(uname -r) lib32gcc-s1
        ;;
esac

# ----------------------------
# Step 3: Install NVIDIA drivers
# ----------------------------
case "$OS" in
    arch)
        $SUDO pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings
        ;;
    fedora)
        $SUDO dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-settings
        ;;
    mint)
        $SUDO apt install -y nvidia-driver nvidia-dkms-$(uname -r) lib32-nvidia-glibc nvidia-settings
        ;;
esac

# ----------------------------
# Step 4: PRIME offloading
# ----------------------------
echo "Setting up PRIME GPU offloading..."
case "$OS" in
    arch)
        if [ ! -f /usr/local/bin/prime-run ]; then
            $SUDO tee /usr/local/bin/prime-run >/dev/null << 'EOF'
#!/bin/sh
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only "$@"
EOF
            $SUDO chmod +x /usr/local/bin/prime-run
        fi
        ;;
    fedora|mint)
        echo "PRIME support already included."
        ;;
esac

# ----------------------------
# Step 5: CUDA
# ----------------------------
echo "Installing CUDA toolkit..."
case "$OS" in
    arch) $SUDO pacman -S --noconfirm cuda ;;
    fedora) $SUDO dnf install -y cuda ;;
    mint) $SUDO apt install -y nvidia-cuda-toolkit ;;
esac

# ----------------------------
# Finished
# ----------------------------
echo "======================================================"
echo "NVIDIA GPU setup complete!"
echo "Verify installation with 'nvidia-smi'."
echo "======================================================"
