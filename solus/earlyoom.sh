#!/bin/bash

# I take very, very little credit for this script.  All kudo's go to my brother from another mother, Tolga Erok...
# I modified a script he made for Fedora to work with Solus.
# Dec 20 2023

# Run from remote location:::...1112
# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/wvpianoman/brian-scripts/main/solus/Solus.sh)"

#   《˘ ͜ʖ ˘》
#
#
#███████╗ ██████╗ ██╗     ██╗   ██╗███████╗    ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
#██╔════╝██╔═══██╗██║     ██║   ██║██╔════╝    ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
#███████╗██║   ██║██║     ██║   ██║███████╗    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝
#╚════██║██║   ██║██║     ██║   ██║╚════██║    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗
#███████║╚██████╔╝███████╗╚██████╔╝███████║    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
#╚══════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝    ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝

clear

# Check if the script is run as root
# if [ "$EUID" -ne 0 ]; then
#     echo "Please run this script as root or using sudo."
#     exit 1
# fi

# Assign a color variable based on the RANDOM number
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
ORANGE='\e[1;93m'
NC='\e[0m'
YELLOW='\e[1;33m'
NC='\e[0m'

# Green, Yellow & Red Messages.
green_msg() {
    tput setaf 2
    echo "[*] ----- $1"
    tput sgr0
}

yellow_msg() {
    tput setaf 3
    echo "[*] ----- $1"
    tput sgr0
}

red_msg() {
    tput setaf 1
    echo "[*] ----- $1"
    tput sgr0
}

# install git

sudo eopkg install git -y

# Clone Earlyoom and compile it yourself

git clone https://github.com/rfjakob/earlyoom.git
cd earlyoom
make

# Optional: Run the integrated self-tests:

# make test

# Start earlyoom automatically by registering it as a service:

sudo make install              # systemd
# sudo make install-initscript   # non-systemd
