#!/bin/sh

set -e

echo "Installing student productivity software..."

PACKAGES="
libreoffice-fresh
vlc
firefox
chromium
okular
pdfarranger
xournalpp
zim
gimp
ffmpeg
syncthing



noto-fonts
noto-fonts-cjk
noto-fonts-emoji
ttf-dejavu
ttf-liberation
"
# Fonts for document compatibility above 
pacman -S --needed --noconfirm $PACKAGES

echo "Refreshing font cache..."
fc-cache -fv

echo "Student software installation complete."
