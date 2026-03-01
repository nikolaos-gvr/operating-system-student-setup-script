#!/bin/sh
#this is a shell script, its purpose is to autodetect the linux distribution that the user runs in in and run another set of scripts based on the needed job, the reason I made this script is to basically "automate" the instalation of a series of packages, enabling reposotories, and making a linux distribution gaming ready.

#The user of course will be allowed to customize which scripts run, although what I would recomend is doing this on a freshly installed system and not doing anything prior to that and not preventing the important scripts running, like the preperation and the repo-enabler script.

# 1) Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    echo "Please run: sudo sh $0"
    exit 1
fi

# 3) Optional sudo keep-alive (only useful if script internally calls sudo)
# If already root, this does nothing harmful
if command -v sudo >/dev/null 2>&1; then
    sudo -v 2>/dev/null

    # Keep sudo alive in background
    (
        while true; do
            sudo -v 2>/dev/null
            sleep 60
        done
    ) &
    SUDO_PID=$!
fi

#detect in which distro is it running

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
else
    echo "Cannot detect distribution."
    exit 1
fi

echo "[DEBUG]: Detected Distribution $DISTRO"

#Run scripts based on detected distribution, the user can uncomment any of the scripts that they want to not run, although i would recomend not tampering with neither the first or the second script in the sequence of each distro.

#I decided not to run the nvidia setup because it is risky and some distros have their own solutions for graphics driver downloads

: <<'END_COMMENT'
case "$DISTRO" in
    arch)
        echo "Detected Arch Linux"
        sh ./Arch-Linux/arch-enable-extra-repos.sh || exit 1
        sh ./Arch-Linux/arch-preparation-setup.sh || exit 1
        #sh ./Arch-Linux/arch-install-nvidia-drivers.sh || exit 1
        sh ./Arch-Linux/arch-student-setup.sh || exit 1
        sh ./Arch-Linux/arch-gaming-setup.sh || exit 1
        ;;

    opensuse-tumbleweed|opensuse)
        echo "Detected openSUSE Tumbleweed"
        sh ./OpenSUSE-Tumbleweed/SUSE-Tumble-enable-extra-repos.sh || exit 1
        sh ./OpenSUSE-Tumbleweed/SUSE-Tumble-preparation-setup.sh || exit 1
        #sh ./OpenSUSE-Tumbleweed/SUSE-Tumble-install-nvidia-drivers.sh || exit 1
        sh ./OpenSUSE-Tumbleweed/SUSE-Tumble-student-setup.sh || exit 1
        sh ./OpenSUSE-Tumbleweed/SUSE-Tumble-gaming-setup.sh || exit 1
        ;;

    linuxmint)
        echo "Detected Linux Mint"
        sh ./Linux-Mint/mint-enable-extra-repos.sh || exit 1
        sh ./Linux-Mint/mint-preparation-setup.sh || exit 1
        #sh ./Linux-Mint/mint-install-nvidia-drivers.sh || exit 1
        sh ./Linux-Mint/mint-student-setup.sh || exit 1
        sh ./Linux-Mint/mint-gaming-setup.sh || exit 1
        ;;

    fedora)
        echo "Detected Fedora"
        sh ./Fedora-Linux/fedora-enable-extra-repos.sh || exit 1
        sh ./Fedora-Linux/fedora-preparation-setup.sh || exit 1
        #sh ./Fedora-Linux/fedora-install-nvidia-drivers.sh || exit 1
        sh ./Fedora-Linux/fedora-student-setup.sh || exit 1
        sh ./Fedora-Linux/fedora-gaming-setup.sh || exit 1
        ;;

    *)
        echo "Unsupported distribution: $DISTRO"
        exit 1
        ;;
esac

END_COMMENT
