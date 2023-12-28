#!/bin/bash

# I take very, very little credit for this script.  All kudo's go to my brother from another mother, Tolga Erok...
# I modified a script he made for Fedora to work with Solus.
# Dec 20 2023

# Run from remote location:::.
# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tolgaerok/tolga-scripts/main/Fedora39/FlatPakApps.sh)"

#   《˘ ͜ʖ ˘》
#
#███████╗██╗      █████╗ ████████╗██████╗  █████╗ ██╗  ██╗     █████╗ ██████╗ ██████╗ ███████╗
#██╔════╝██║     ██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██║ ██╔╝    ██╔══██╗██╔══██╗██╔══██╗██╔════╝
#█████╗  ██║     ███████║   ██║   ██████╔╝███████║█████╔╝     ███████║██████╔╝██████╔╝███████╗
#██╔══╝  ██║     ██╔══██║   ██║   ██╔═══╝ ██╔══██║██╔═██╗     ██╔══██║██╔═══╝ ██╔═══╝ ╚════██║
#██║     ███████╗██║  ██║   ██║   ██║     ██║  ██║██║  ██╗    ██║  ██║██║     ██║     ███████║
#╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝
#

# Prompt user for confirmation
read -p ")==> This script will install Flatpak applications and make system modifications. Do you want to continue? (y/n): " choice
if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    echo "Installation aborted."
    exit 0
fi



echo -e "\e[1;32m[✔]\e[0m Checking updates for installed flatpak programs...\n"
flatpak update -y
sleep 1

echo "#####################################"
echo
echo "Enabling Flatpak Theming Overrides"
echo

# Check and set XDG_RUNTIME_DIR
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro
sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro

sudo flatpak override --env=gfx.webrender.all=true \
    --env=media.ffmpeg.vaapi.enabled=true \
    --env=widget.dmabuf.force-enabled=true \
    org.mozilla.firefox

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# Check if the directory exists before attempting to remove it
if [ -d "/var/tmp/flatpak-cache-*" ]; then
    echo -e "\e[1;32m[✔]\e[0m Removing Old Flatpak Cruft...\n"
    sudo rm -rfv /var/tmp/flatpak-cache-*
else
    echo -e "\e[1;32m[✔]\e[0m No old Flatpak cruft found.\n"
fi

sleep 1

# Display all platpaks installed on system
flatpak --columns=app,name,size,installation list
echo -e "\e[1;32m[✔]\e[0m List of flatpaks on system...\n"

echo "Installation completed. You can now run the installed applications."
sleep 3
