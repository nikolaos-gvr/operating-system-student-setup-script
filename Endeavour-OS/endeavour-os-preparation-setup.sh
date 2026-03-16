#!/bin/sh

USER_NAME=${SUDO_USER:-$(logname)}

echo "Updating system..."
pacman -Syu --noconfirm

echo "Installing essential development packages..."

ESSENTIAL_PACKAGES="
git
curl
wget
base-devel
python
python-pip
nodejs
npm
jdk-openjdk
cmake
clang
vim
nano
neovim
htop
fastfetch
tree
zip
unzip
p7zip
rsync
jq
tmux
zsh
"

pacman -S --needed --noconfirm $ESSENTIAL_PACKAGES

echo "Installing yay (AUR helper)..."

runuser -u "$USER_NAME" -- sh <<'EOF'
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit

git clone https://aur.archlinux.org/yay.git
cd yay || exit

makepkg -si --noconfirm

cd ~
rm -rf "$TMP_DIR"
EOF

echo "AUR support installed."