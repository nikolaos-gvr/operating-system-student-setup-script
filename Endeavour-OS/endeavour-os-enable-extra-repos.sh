#!/bin/sh

PACMAN_CONF="/etc/pacman.conf"
echo " "
echo "Checking extra repositories on Arch/EndeavourOS..."
echo " "
enable_if_needed() {
    REPO_NAME=$1

    # Check if repo is enabled
    grep -E "^\[$REPO_NAME\]" "$PACMAN_CONF" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo " "
        echo "[$REPO_NAME] repository is already enabled."
        echo " "
    else
        # Check if repo exists but commented
        grep -E "^\s*#\s*\[$REPO_NAME\]" "$PACMAN_CONF" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo " "
            echo "[$REPO_NAME] repository is not enabled. Enabling..."
            echo " "
            # Uncomment the repo line
            sudo sed -i "/^\s*#\s*\[$REPO_NAME\]/s/^#\s*//" "$PACMAN_CONF"
            # Uncomment the next Include line
            sudo sed -i "/^\[$REPO_NAME\]/ {n;s/^#\s*//}" "$PACMAN_CONF"
            echo " "
            echo "[$REPO_NAME] enabled."
            echo " "
        else
            echo " "
            echo "[$REPO_NAME] repository not found in $PACMAN_CONF."
            echo " "
        fi
    fi
}

# Check and enable repos
echo " "
enable_if_needed "multilib"
enable_if_needed "endeavouros"
echo " "

echo "Updating package database..."
sudo pacman -Sy --noconfirm
echo " "

echo "Done."