#!/bin/sh

# Exit immediately if something fails
set -e

# 1) Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    echo "Please run: sudo sh $0"
    exit 1
fi

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(printf '%s' "$ID" | tr '[:upper:]' '[:lower:]')
else
    echo "Cannot detect distribution."
    exit 1
fi

echo "[INFO] -> Detected distribution: $DISTRO"

case "$DISTRO" in
    arch)
        #echo "[INFO] -> auto-setup: enabling extra repos for Arch Linux"
        #echo "[INFO] -> auto-setup: prepearing for setup of Arch Linux"
        #echo "[INFO] -> auto-setup: installing "student" packages for Arch Linux"
        #echo "[INFO] -> auto-setup: installing gaming related packages for Arch Linux"
        #sh ./Arch-Linux/arch-enable-extra-repos.sh
        #sh ./Arch-Linux/arch-preparation-setup.sh
        #sh ./Arch-Linux/arch-student-setup.sh
        #sh ./Arch-Linux/arch-gaming-setup.sh
        ;;

    endeavouros)
        echo "[INFO] -> auto-setup: enabling extra repos for Endeavour OS"
        echo " "
        sh ./Endeavour-OS/endeavour-os-enable-extra-repos.sh #Not needed since it has everything ready out of the box but keeping it to check if the needed repos are enabled
        echo " "
        echo "[INFO] -> auto-setup: prepearing for setup of Endeavour OS"
        echo " "
        sh ./Endeavour-OS/endeavour-os-preparation-setup.sh
        echo " "
        echo "[INFO] -> auto-setup: installing "student" packages for Endeavour OS"
        echo " "
        sh ./Endeavour-OS/endeavour-os-student-setup.sh
        echo " "
        echo "[INFO] -> auto-setup: installing gaming related packages for Endeavour OS"
        echo " "
        sh ./Endeavour-OS/endeavour-os-gaming-setup.sh
        echo " "
        #Edeavour OS is Arch based but since it has multilib and aur already enabled I decided to use a separate set of scripts
        
        
        
        
        ;;

    opensuse-tumbleweed|opensuse)
        echo "[INFO] -> OpenSUSE Tumbleweed was detected but it is required to inform you that even if this distro is intended to be supported the scripts have not been made yet"
        #echo "[INFO] -> auto-setup: enabling extra repos for OpenSUSE Tumbleweed"
        #echo "[INFO] -> auto-setup: prepearing for setup of OpenSUSE Tumbleweed"
        #echo "[INFO] -> auto-setup: installing "student" packages for OpenSUSE Tumbleweed"
        #echo "[INFO] -> auto-setup: installing gaming related packages for OpenSUSE Tumbleweed"
        #sh ./OpenSUSE-Tumbleweed/SUSE-Tumble-enable-extra-repos.sh
        #sh ./OpenSUSE-Tumbleweed/SUSE-Tumble-preparation-setup.sh
        #sh ./OpenSUSE-Tumbleweed/SUSE-Tumble-student-setup.sh
        #sh ./OpenSUSE-Tumbleweed/SUSE-Tumble-gaming-setup.sh
        ;;

    linuxmint|ubuntu) 
        echo "[INFO] -> Ubuntu/Mint was detected but it is required to inform you that even if this distro is intended to be supported the scripts have not been made yet"
        #remove ubuntu when you finish testing, ubuntu is only an option for testing purposes
        #echo "[INFO] -> auto-setup: enabling extra repos for Linux Mint"
        #echo "[INFO] -> auto-setup: prepearing for setup of Linux Mint"
        #echo "[INFO] -> auto-setup: installing "student" packages for Linux Mint"
        #echo "[INFO] -> auto-setup: installing gaming related packages for Linux Mint"
        #sh ./Linux-Mint/mint-enable-extra-repos.sh
        #sh ./Linux-Mint/mint-preparation-setup.sh
        #sh ./Linux-Mint/mint-student-setup.sh
        #sh ./Linux-Mint/mint-gaming-setup.sh
        ;;

    fedora)
        echo "[INFO] -> Fedora was detected but it is required to inform you that even if this distro is intended to be supported the scripts have not been made yet"
        #echo "[INFO] -> auto-setup: enabling extra repos for Fedora Linux"
        #echo "[INFO] -> auto-setup: prepearing for setup of Fedora Linux"
        #echo "[INFO] -> auto-setup: installing "student" packages for Fedora Linux"
        #echo "[INFO] -> auto-setup: installing gaming related packages for Fedora Linux"
        #sh ./Fedora-Linux/fedora-enable-extra-repos.sh
        #sh ./Fedora-Linux/fedora-preparation-setup.sh
        #sh ./Fedora-Linux/fedora-student-setup.sh
        #sh ./Fedora-Linux/fedora-gaming-setup.sh
        ;;

    *)
        echo "Unsupported distribution: $DISTRO"
        exit 1
        ;;
esac
