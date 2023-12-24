#!/bin/bash

# I take very, very little credit for this script.  All kudo's go to my brother from another mother, Tolga Erok...
# I modified a script he made for Fedora to work with Solus.
# Dec 20 2023

# Brians online script
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
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

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

# Declare Paths & Settings
CONFIG_CONTENT="[General]\nNumlock=on"
PROF_PATH="/etc/profile"
SDDM_CONF="/etc/sddm.conf.d/sddm.conf"
SSH_PATH="/etc/ssh/sshd_config"
SSH_PORT=""
SWAP_PATH="/swapfile"
SWAP_SIZE=2G
SYS_PATH="/etc/sysctl.conf"

sudo snap install figlet
#clear

sudo go install github.com/charmbracelet/gum@latest
#clear

# none [mq-deadline] kyber bfq
# Super tweak I/O scheduler
echo -e "\n${BLUE}Configuring I/O Scheduler to: ${NC}\n"
echo "mq-deadline" | sudo tee /sys/block/sda/queue/scheduler
printf "\n${YELLOW}I/O Scheduler has been set to ==>  ${NC}"
cat /sys/block/sda/queue/scheduler
echo ""
gum spin --spinner dot --title "Stand-by..." -- sleep 2

# Turn on NumLock in SDDM login screen
# Check if the SDDM configuration file exists
if [ ! -f "$SDDM_CONF" ]; then
    # If not, create the file and echo the configuration content into it
    echo -e "$CONFIG_CONTENT" | sudo tee "$SDDM_CONF" >/dev/null
else
    # If the file exists, append the configuration content
    echo -e "$CONFIG_CONTENT" | sudo tee -a "$SDDM_CONF" >/dev/null
fi

echo""
# for_exit "figlet"
figlet Solus Tweaks
gum spin --spinner dot --title "Stand-by..." -- sleep 2

# Function to display messages
display_message() {
    clear
    echo -e "\n                  Brian's online Solus updater\n"
    echo -e "\e[34m|--------------------\e[33m Currently configuring:\e[34m-------------------|"
    echo -e "|${YELLOW}==>${NC}  $1"
    echo -e "\e[34m|--------------------------------------------------------------|\e[0m"
    echo ""
    gum spin --spinner dot --title "Stand-by..." -- sleep 1
}

# Function to check and display errors
check_error() {
    if [ $? -ne 0 ]; then
        display_message "[${RED}✘${NC}] Error occurred !!"
        # Print the error details
        echo "Error details: $1"
        gum spin --spinner dot --title "Stand-by..." -- sleep 8
    fi
}

######################################################################################
# Change Hostname
######################################################################################
change_hotname() {
    current_hostname=$(hostname)

    display_message "Changing HOSTNAME: $current_hostname"

    # Get the new hostname from the user
    read -p "Enter the new hostname: " new_hostname

    # Change the system hostname
    sudo hostnamectl set-hostname "$new_hostname"

    # Update /etc/hosts file
    sudo sed -i "s/127.0.0.1.*localhost/127.0.0.1 $new_hostname localhost/" /etc/hosts

    # Display the new hostname
    echo "Hostname changed to: $new_hostname"
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
}

######################################################################################
# Function to update the system
######################################################################################
update_system() {
    display_message "Updating the system...."

    # Update the package manager
    sudo eopkg rbs -y
    sudo eopkg up -y

    check_error

    display_message "System updated successfully."
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
}

######################################################################################
# Function to install firmware updates with a countdown on error
######################################################################################
install_firmware() {
    display_message "Installing firmware updates..."

    sudo snap install fwupd

    # Attempt to install firmware updates
    sudo fwupdmgr get-devices
    sudo fwupdmgr refresh --force
    sudo fwupdmgr get-updates
    sudo fwupdmgr update

    # Check for errors during firmware updates
    if [ $? -ne 0 ]; then
        display_message "Error occurred during firmware updates.."

        # Countdown for 10 seconds on error
        for i in {4..1}; do
            echo -ne "Continuing in $i seconds... \r"
            sleep 1
        done
        echo -e "Continuing with the script."
    else
        display_message "Firmware updated successfully."
    fi
}



######################################################################################
# Function to optimize battery life on lappy, in theory.... LOL
######################################################################################
optimize_battery() {
    display_message "Optimizing battery life..."

    # Check if the battery exists
    if [ -e "/sys/class/power_supply/BAT0" ]; then
        # Install TLP and mask power-profiles-daemon
        # sudo dnf install -y tlp tlp-rdw
        sudo eopkg install -y tlp
        sudo systemctl mask power-profiles-daemon

        # Install powertop and apply auto-tune
        # sudo dnf install -y powertop
        sudo eopkg install -y powertop
        sudo powertop --auto-tune

        display_message "Battery optimization completed."
        gum spin --spinner dot --title "Stand-by..." -- sleep 2
    else
        display_message "No battery found. Skipping battery optimization."
        gum spin --spinner dot --title "Stand-by..." -- sleep 2
    fi
}

######################################################################################
# Function to install multimedia codecs, old fedora hacks to meet new standards (F39)
######################################################################################
install_multimedia_codecs() {
    display_message "[${GREEN}✔${NC}]  Installing multimedia codecs..."

    sudo dnf groupupdate -y 'core' 'multimedia' 'sound-and-video' --setopt='install_weak_deps=False' --exclude='PackageKit-gstreamer-plugin' --allowerasing && sync
    sudo dnf swap -y 'ffmpeg-free' 'ffmpeg' --allowerasing
    sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg
    sudo dnf install -y lame\* --exclude=lame-devel
    sudo dnf group upgrade --with-optional Multimedia -y

    # Enable support for Cisco OpenH264 codec
    sudo dnf config-manager --set-enabled fedora-cisco-openh264 -y
    sudo dnf install gstreamer1-plugin-openh264 mozilla-openh264 -y

    display_message "[${GREEN}✔${NC}]  Multimedia codecs installed successfully."
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
}


######################################################################################
# Function to install H/W Video Acceleration for AMD or Intel chipset
######################################################################################
install_hw_video_acceleration_amd_or_intel() {
    display_message "Checking for AMD chipset..."

    # Check for AMD chipset
    if lspci | grep -i amd &>/dev/null; then
        display_message "[${GREEN}✔${NC}]  AMD chipset detected. Installing AMD video acceleration..."

        sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
        sudo dnf swap -y swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
        sudo dnf config-manager --set-enabled fedora-cisco-openh264
        sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264

        display_message "[${GREEN}✔${NC}]  H/W Video Acceleration for AMD chipset installed successfully."
    else
        display_message "[${RED}✘${NC}]  No AMD chipset found. Pausing for user confirmation..."

        # Pause for user confirmation
        read -p "Press Enter to check for Intel chipset..."

        display_message "Checking for Intel chipset..."

        # Check for Intel chipset
        if lspci | grep -i intel &>/dev/null; then
            display_message "Intel chipset detected. Installing Intel video acceleration..."

            sudo dnf install -y intel-media-driver

            # Install video acceleration packages
            sudo dnf install libva libva-utils xorg-x11-drv-intel -y

            display_message "[${GREEN}✔${NC}]  H/W Video Acceleration for Intel chipset installed successfully."
            gum spin --spinner dot --title "Stand-by..." -- sleep 2
        else
            display_message "No Intel chipset found. Skipping H/W Video Acceleration installation."
            gum spin --spinner dot --title "Stand-by..." -- sleep 2
        fi
    fi
}

######################################################################################
# Function to set UTC Time for dual boot issues, old hack of mine
######################################################################################
set_utc_time() {
    display_message "Setting UTC Time..."

    sudo timedatectl set-local-rtc '0'

    display_message "[${GREEN}✔${NC}]  UTC Time set successfully."
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
}


######################################################################################
# Function to disable NetworkManager-wait-online.service
######################################################################################
disable_network_manager_wait_online() {
    display_message "[${GREEN}✔${NC}]  Disabling NetworkManager-wait-online.service..."

    # Disable NetworkManager-wait-online.service
    sudo systemctl disable NetworkManager-wait-online.service

    display_message "NetworkManager-wait-online.service disabled successfully."
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
}


######################################################################################
# Function to check if mitigations=off is present in GRUB configuration
######################################################################################


download_and_install_code_tv() {
    local download_url="$1"
    local download_location="$2"

    # Check if the application is already installed
    if command -v "$3" &>/dev/null; then
        display_message "$3 is already installed. Skipping installation."
        sleep 1
    else
        # Download and install the application
        display_message "[${GREEN}✔${NC}]  Downloading $3..."
        wget -O "$download_location" "$download_url"

        display_message "[${GREEN}✔${NC}]  Installing $3..."
        sudo dnf install "$download_location" -y

        # Cleanup
        display_message "[${GREEN}✔${NC}]  Cleaning up /tmp..."
        rm "$download_location"
        gum spin --spinner dot --title "Stand-by..." -- sleep 2

        display_message "[${GREEN}✔${NC}]  $3 installation completed."
        gum spin --spinner dot --title "Stand-by..." -- sleep 2
    fi

}

# Function to install a package
for_exit() {
    package_name="$1"

    # Check if the package is already installed
    if command -v "$package_name" &>/dev/null; then
        # If the package is already installed, do nothing
        echo "$package_name is already installed. Exiting."
        # sleep 1
        clear
    else
        # Install the package
        sudo dnf install -y "$package_name"
        echo "$package_name has been installed."
        # sleep 1
        clear
    fi
}

# Function to download and install a package
download_and_install() {
    url="$1"
    location="$2"
    package_name="$3"

    # Check if the package is already installed
    if sudo dnf list installed "$package_name" &>/dev/null; then
        display_message "[${RED}✘${NC}] $package_name is already installed. Skipping installation."
        sleep 1
        return
    fi

    # Download the package
    wget "$url" -O "$location"

    # Install the package
    sudo dnf install -y "$location"
}

# Template
# display_message "[${GREEN}✔${NC}]
# display_message "[${RED}✘${NC}]

# Function to check port 22
check_port22() {
    if pgrep sshd >/dev/null; then
        display_message "[${GREEN}✔${NC}] SSH service is running on port 22"
        gum spin --spinner dot --title "Stand-by..." -- sleep 2
    else
        display_message "${RED}[✘]${NC} SSH service is not running on port 22. Install and enable SSHD service.\n"
        gum spin --spinner dot --title "Stand-by..." -- sleep 2
        check_error
    fi
}

# Function to check if a service is active
is_service_active() {
    systemctl is-active "$1" &>/dev/null
}

# Function to check if a service is enabled
is_service_enabled() {
    systemctl is-enabled "$1" &>/dev/null
}

# Function to print text in yellow color
print_yellow() {
    echo -e "\e[93m$1\e[0m"
}

install_apps() {
    display_message "[${GREEN}✔${NC}]  Installing afew personal apps..."

    sudo dnf -y up
    sudo dnf -y autoremove
    sudo dnf -y clean all

    # Install Apps

    sudo dnf install -y PackageKit dconf-editor digikam direnv duf earlyoom espeak ffmpeg-libs figlet gedit gimp gimp-devel git gnome-font-viewer
    sudo dnf install -y grub-customizer kate libdvdcss libffi-devel lsd mpg123 neofetch openssl-devel p7zip p7zip-plugins pip python3 python3-pip
    sudo dnf install -y rhythmbox rygel shotwell sshpass sxiv timeshift unrar unzip cowsay fortune
    sudo dnf install -y sshfs fuse-sshfs rsync openssh-server openssh-clients
    sudo dnf install -y variety virt-manager wget xclip zstd fd-find fzf gtk3 rygel

    /usr/bin/rygel-preferences

    ## Networking packages
    sudo dnf -y install iptables iptables-services nftables

    ## System utilities
    sudo dnf -y install bash-completion busybox crontabs ca-certificates curl dnf-plugins-core dnf-utils gnupg2 nano screen ufw unzip vim wget zip

    ## Programming and development tools
    sudo dnf -y install autoconf automake bash-completion git libtool make pkg-config python3 python3-pip

    ## Additional libraries and dependencies
    sudo dnf -y install bc binutils haveged jq libsodium libsodium-devel PackageKit qrencode socat

    ## Miscellaneous
    sudo dnf -y install dialog htop net-tools

    sudo dnf swap -y libavcodec-free libavcodec-freeworld --allowerasing
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

    display_message "[${GREEN}✔${NC}]  Installing GUM"

    echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
    sudo yum install gum -y

    gum spin --spinner dot --title "GUM installed" -- sleep 2

    ## Make a backup of the original sysctl.conf file
    display_message "[${GREEN}✔${NC}]  Tweaking network settings"

    cp $SYS_PATH /etc/sysctl.conf.bak

    echo
    yellow_msg 'Default sysctl.conf file Saved. Directory: /etc/sysctl.conf.bak'
    echo
    gum spin --spinner dot --title "Stand-by..." -- sleep 1

    echo
    yellow_msg 'Optimizing the Network...'
    echo
    gum spin --spinner dot --title "tweaking network" -- sleep 3

    sed -i -e '/fs.file-max/d' \
        -e '/net.core.default_qdisc/d' \
        -e '/net.core.netdev_max_backlog/d' \
        -e '/net.core.optmem_max/d' \
        -e '/net.core.somaxconn/d' \
        -e '/net.core.rmem_max/d' \
        -e '/net.core.wmem_max/d' \
        -e '/net.core.rmem_default/d' \
        -e '/net.core.wmem_default/d' \
        -e '/net.ipv4.tcp_rmem/d' \
        -e '/net.ipv4.tcp_wmem/d' \
        -e '/net.ipv4.tcp_congestion_control/d' \
        -e '/net.ipv4.tcp_fastopen/d' \
        -e '/net.ipv4.tcp_fin_timeout/d' \
        -e '/net.ipv4.tcp_keepalive_time/d' \
        -e '/net.ipv4.tcp_keepalive_probes/d' \
        -e '/net.ipv4.tcp_keepalive_intvl/d' \
        -e '/net.ipv4.tcp_max_orphans/d' \
        -e '/net.ipv4.tcp_max_syn_backlog/d' \
        -e '/net.ipv4.tcp_max_tw_buckets/d' \
        -e '/net.ipv4.tcp_mem/d' \
        -e '/net.ipv4.tcp_mtu_probing/d' \
        -e '/net.ipv4.tcp_notsent_lowat/d' \
        -e '/net.ipv4.tcp_retries2/d' \
        -e '/net.ipv4.tcp_sack/d' \
        -e '/net.ipv4.tcp_dsack/d' \
        -e '/net.ipv4.tcp_slow_start_after_idle/d' \
        -e '/net.ipv4.tcp_window_scaling/d' \
        -e '/net.ipv4.tcp_ecn/d' \
        -e '/net.ipv4.ip_forward/d' \
        -e '/net.ipv4.udp_mem/d' \
        -e '/net.ipv6.conf.all.disable_ipv6/d' \
        -e '/net.ipv6.conf.all.forwarding/d' \
        -e '/net.ipv6.conf.default.disable_ipv6/d' \
        -e '/net.unix.max_dgram_qlen/d' \
        -e '/vm.min_free_kbytes/d' \
        -e '/vm.swappiness/d' \
        -e '/vm.vfs_cache_pressure/d' \
        "$SYS_PATH"

    display_message "[${GREEN}✔${NC}]  Previous settings deleted"
    gum spin --spinner dot --title "Re-accessing, stanby" -- sleep 2

    ## Add new parameteres. Read More: https://github.com/hawshemi/Linux-Optimizer/blob/main/files/sysctl.conf

    cat <<EOF >>"$SYS_PATH"
fs.file-max = 67108864
net.core.default_qdisc = fq_codel
net.core.netdev_max_backlog = 32768
net.core.optmem_max = 65536
net.core.somaxconn = 65536
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.ipv4.tcp_rmem = 8192 1048576 16777216
net.ipv4.tcp_wmem = 8192 1048576 16777216
net.ipv4.tcp_congestion_control = westwood
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_fin_timeout = 25
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 7
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_max_orphans = 819200
net.ipv4.tcp_max_syn_backlog = 20480
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_mem = 65536 1048576 16777216
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_ecn = 1
net.ipv4.ip_forward = 1
net.ipv4.udp_mem = 65536 1048576 16777216
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.disable_ipv6 = 0
net.unix.max_dgram_qlen = 50
vm.min_free_kbytes = 65536
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF

    display_message "[${GREEN}✔${NC}]  Adding New network settings"
    sudo sysctl -p
    sudo systemctl restart systemd-sysctl
    echo ""
    gum spin --spinner dot --title "Restarting systemd custom settings.." -- sleep 4

    echo
    green_msg 'Network is Optimized.'
    echo
    gum spin --spinner dot --title "Starting SSH..." -- sleep 3

    # Start and enable SSH
    sudo systemctl start sshd
    sudo systemctl enable sshd
    display_message "[${GREEN}✔${NC}]  Checking SSh port"
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
    check_port22
    sudo systemctl status sshd

    display_message "[${GREEN}✔${NC}]  Setup KDE Wallet"
    gum spin --spinner dot --title "Standby.." -- sleep 1
    # Install Plasma related packages
    sudo dnf install -y \
        ksshaskpass

    mkdir -p ${HOME}/.config/autostart/
    mkdir -p ${HOME}/.config/environment.d/

    # Use the KDE Wallet to store ssh key passphrases
    # https://wiki.archlinux.org/title/KDE_Wallet#Using_the_KDE_Wallet_to_store_ssh_key_passphrases
    tee ${HOME}/.config/autostart/ssh-add.desktop <<EOF
[Desktop Entry]
Exec=ssh-add -q
Name=ssh-add
Type=Application
EOF

    tee ${HOME}/.config/environment.d/ssh_askpass.conf <<EOF
SSH_ASKPASS='/usr/bin/ksshaskpass'
GIT_ASKPASS=ksshaskpass
SSH_ASKPASS=ksshaskpass
SSH_ASKPASS_REQUIRE=prefer
EOF

    display_message "[${GREEN}✔${NC}]  Install vitualization group and set permissions"
    gum spin --spinner dot --title "Standby.." -- sleep 1
    # Install virtualization group
    sudo dnf install -y @virtualization

    # Enable libvirtd service
    sudo systemctl enable libvirtd

    # Add user to libvirt group
    sudo usermod -a -G libvirt ${USER}

    # Start earlyloom services
    display_message "[${GREEN}✔${NC}]  Starting earlyloom services"
    sudo systemctl start earlyoom
    sudo systemctl enable --now earlyoom
    echo ""
    gum spin --spinner dot --title "Restarting Earlyloom.." -- sleep 2.5
    display_message "[${GREEN}✔${NC}]  Checking earlyloom status service"

    # Check EarlyOOM status
    earlyoom_status=$(systemctl status earlyoom | cat)

    # Check if EarlyOOM is active and enabled
    if is_service_active earlyoom; then
        active_status="Active"
    else
        active_status="Inactive"
    fi

    if is_service_enabled earlyoom; then
        enabled_status=$(print_yellow "Enabled")
    else
        enabled_status="Disabled"
    fi

    # Get memory information
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')

    # Display information
    echo -e "EarlyOOM Status: $active_status"
    echo -e "Service Enablement: $enabled_status"
    echo -e "Total Memory: $mem_total KB"
    echo -e "Total Swap: $swap_total KB\n\n"
    gum spin --spinner dot --title "Standby.." -- sleep 1
    sudo journalctl -u earlyoom | grep sending
    gum spin --spinner dot --title "Standby.." -- sleep 3

    # Install fedora preload
    display_message "[${GREEN}✔${NC}]  Install fedora preload"
    sudo dnf copr enable atim/preload -y && sudo dnf install preload -y
    display_message "[${GREEN}✔${NC}]  Enable fedora preload service"
    sudo systemctl enable --now preload.service
    gum spin --spinner dot --title "Standby.." -- sleep 1.5

    # Install some fonts
    display_message "[${GREEN}✔${NC}]  Installing some fonts"
    sudo dnf install -y fontawesome-fonts powerline-fonts
    sudo mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts && curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf
    wget https://github.com/tolgaerok/fonts-tolga/raw/main/WPS-FONTS.zip
    unzip WPS-FONTS.zip -d /usr/share/fonts

    zip_file="Apple-Fonts-San-Francisco-New-York-master.zip"

    # Check if the ZIP file exists
    if [ -f "$zip_file" ]; then
        # Remove existing ZIP file
        sudo rm -f "$zip_file"
        echo "Existing ZIP file removed."
    fi

    # Download the ZIP file
    curl -LJO https://github.com/tolgaerok/Apple-Fonts-San-Francisco-New-York/archive/refs/heads/master.zip

    # Check if the download was successful
    if [ -f "$zip_file" ]; then
        # Unzip the contents to the system-wide fonts directory
        sudo unzip -o "$zip_file" -d /usr/share/fonts/

        # Update font cache
        sudo fc-cache -f -v

        # Remove the ZIP file
        rm "$zip_file"

        display_message "[${GREEN}✔${NC}] Apple fonts installed successfully."
        echo ""
        gum spin --spinner dot --title "Re-thinking... 1 sec" -- sleep 2
    else
        display_message "[${RED}✘${NC}] Download failed. Please check the URL and try again."
        gum spin --spinner dot --title "Stand-by..." -- sleep 2
    fi

    # Reloading Font
    sudo fc-cache -vf

    # Removing zip Files
    rm ./WPS-FONTS.zip
    sudo fc-cache -f -v

    sudo dnf install fontconfig-font-replacements -y --skip-broken && sudo dnf install fontconfig-enhanced-defaults -y --skip-broken

    # Install OpenRGB.
    display_message "[${GREEN}✔${NC}]  Installing OpenRGB"
    sudo modprobe i2c-dev && sudo modprobe i2c-piix4 && sudo dnf install openrgb -y

    # Install Docker
    display_message "[${GREEN}✔${NC}]  Installing Docker..this takes awhile"
    echo ""
    gum spin --spinner dot --title "If this is the first time installing docker, it usually takes VERY long" -- sleep 2
    sudo dnf install docker -y

    # Install Btrfs
    display_message "[${GREEN}✔${NC}]  Installing btrfs assistant.."
    package_url="https://kojipkgs.fedoraproject.org//packages/btrfs-assistant/1.8/2.fc39/x86_64/btrfs-assistant-1.8-2.fc39.x86_64.rpm"
    package_name=$(echo "$package_url" | awk -F'/' '{print $NF}')

    # Check if the package is installed
    if rpm -q "$package_name" >/dev/null; then
        display_message "[${RED}✘${NC}] $package_name is already installed."
        gum spin --spinner dot --title "Standby.." -- sleep 1
    else
        # Package is not installed, so proceed with the installation
        display_message "[${GREEN}✔${NC}]  $package_name is not installed. Installing..."
        sudo dnf install -y "$package_url"
        if [ $? -eq 0 ]; then
            display_message "[${GREEN}✔${NC}]  $package_name has been successfully installed."
            gum spin --spinner dot --title "Standby.." -- sleep 1
        else
            display_message "[${RED}✘${NC}] Failed to install $package_name."
            gum spin --spinner dot --title "Standby.." -- sleep 1
        fi
    fi

    # Install google
    display_message "[${GREEN}✔${NC}]  Installing Google chrome"
    if command -v google-chrome &>/dev/null; then
        display_message "[${RED}✘${NC}] Google Chrome is already installed. Skipping installation."
        gum spin --spinner dot --title "Standby.." -- sleep 1
    else
        # Install Google Chrome
        display_message "[${GREEN}✔${NC}]  Installing Google Chrome browser..."
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
        sudo dnf install -y ./google-chrome-stable_current_x86_64.rpm
        rm -f google-chrome-stable_current_x86_64.rpm
    fi

    # Download and install TeamViewer
    display_message "[${GREEN}✔${NC}]  Downloading && install TeamViewer"
    teamviewer_url="https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm?utm_source=google&utm_medium=cpc&utm_campaign=au%7Cb%7Cpr%7C22%7Cjun%7Ctv-core-download-sn%7Cfree%7Ct0%7C0&utm_content=Download&utm_term=teamviewer+download"
    teamviewer_location="/tmp/teamviewer.x86_64.rpm"
    download_and_install "$teamviewer_url" "$teamviewer_location" "teamviewer"

    # Download and install Visual Studio Code
    display_message "[${GREEN}✔${NC}]  Downloading && install Vscode"
    vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
    vscode_location="/tmp/vscode.rpm"
    download_and_install "$vscode_url" "$vscode_location" "code"

    # Install extra package
    display_message "[${GREEN}✔${NC}]  Installing Extra RPM packages"
    sudo dnf groupupdate -y sound-and-video
    sudo dnf group upgrade -y --with-optional Multimedia
    sudo dnf groupupdate -y sound-and-video --allowerasing --skip-broken
    sudo dnf groupupdate multimedia sound-and-video

    # Cleanup
    display_message "[${GREEN}✔${NC}]  Cleaning up downloaded /tmp folder"
    rm "$download_location"

    display_message "[${GREEN}✔${NC}]  Installing SAMBA and dependencies"

    # Install Samba and its dependencies
    sudo dnf install samba samba-client samba-common cifs-utils samba-usershares -y

    # Enable and start SMB and NMB services
    display_message "[${GREEN}✔${NC}]  SMB && NMB services started"
    sudo systemctl enable smb.service nmb.service
    sudo systemctl start smb.service nmb.service

    # Restart SMB and NMB services (optional)
    sudo systemctl restart smb.service nmb.service

    # Configure the firewall
    display_message "[${GREEN}✔${NC}]  Firewall Configured"
    sudo firewall-cmd --add-service=samba --permanent
    sudo firewall-cmd --add-service=samba
    sudo firewall-cmd --runtime-to-permanent
    sudo firewall-cmd --reload

    # Set SELinux booleans
    display_message "[${GREEN}✔${NC}]  SELINUX parameters set "
    sudo setsebool -P samba_enable_home_dirs on
    sudo setsebool -P samba_export_all_rw on
    sudo setsebool -P smbd_anon_write 1

    # Create samba user/group
    display_message "[${GREEN}✔${NC}]  Create smb user and group"
    read -r -p "Set-up samba user & group's
" -t 2 -n 1 -s

    # Prompt for the desired username for samba
    read -p $'\n'"Enter the USERNAME to add to Samba: " sambausername

    # Prompt for the desired name for samba
    read -p $'\n'"Enter the GROUP name to add username to Samba: " sambagroup

    sudo groupadd $sambagroup
    sudo useradd -m $sambausername
    sudo smbpasswd -a $sambausername
    sudo usermod -aG $sambagroup $sambausername

    read -r -p "
Continuing..." -t 1 -n 1 -s

    # Configure custom samba folder
    read -r -p "Create and configure custom samba folder located at /home/fedora39
" -t 2 -n 1 -s

    sudo mkdir /home/fedora39
    sudo chgrp samba /home/fedora39
    sudo chmod 770 /home/fedora39
    sudo restorecon -R /home/fedora39

    # Create the sambashares group if it doesn't exist
    sudo groupadd -r sambashares

    # Create the usershares directory and set permissions
    sudo mkdir -p /var/lib/samba/usershares
    sudo chown $username:sambashares /var/lib/samba/usershares
    sudo chmod 1770 /var/lib/samba/usershares

    # Restore SELinux context for the usershares directory
    display_message "[${GREEN}✔${NC}]  Restore SELinux for usershares folder"
    sudo restorecon -R /var/lib/samba/usershares

    # Add the user to the sambashares group
    display_message "[${GREEN}✔${NC}]  Adding user to usershares"
    sudo gpasswd sambashares -a $username

    # Add the user to the sambashares group (alternative method)
    sudo usermod -aG sambashares $username

    # Restart SMB and NMB services (optional)
    display_message "[${GREEN}✔${NC}]  Restart SMB && NMB (samba) services"
    sudo systemctl restart smb.service nmb.service

    # Set up SSH Server on Host
    display_message "[${GREEN}✔${NC}]  Setup SSH and start service.."
    sudo systemctl enable sshd && sudo systemctl start sshd

    display_message "[${GREEN}✔${NC}]  Installation completed."
    gum spin --spinner dot --title "Standby.." -- sleep 3

    # Check for errors during installation
    if [ $? -eq 0 ]; then
        display_message "Apps installed successfully."
        gum spin --spinner dot --title "Standby.." -- sleep 2
    else
        display_message "[${RED}✘${NC}] Error: Unable to install Apps."
        gum spin --spinner dot --title "Standby.." -- sleep 2
    fi
}

# Template
# display_message "[${GREEN}✔${NC}]
# display_message "[${RED}✘${NC}]

cleanup_fedora() {
    # Clean package cache
    display_message "[${GREEN}✔${NC}]  Time to clean up system..."
    sudo dnf clean all

    # Remove unnecessary dependencies
    sudo dnf autoremove -y

    # Sort the lists of installed packages and packages to keep
    display_message "[${GREEN}✔${NC}]  Sorting out list of installed packages and packages to keep..."
    comm -23 <(sudo dnf repoquery --installonly --latest-limit=-1 -q | sort) <(sudo dnf list installed | awk '{print $1}' | sort) >/tmp/orphaned-pkgs

    if [ -s /tmp/orphaned-pkgs ]; then
        sudo dnf remove $(cat /tmp/orphaned-pkgs) -y --skip-broken
    else
        display_message "[${GREEN}✔${NC}]  Congratulations, no orphaned packages found."
    fi

    # Clean up temporary files
    display_message "[${GREEN}✔${NC}]  Clean up temporary files ..."
    sudo rm -rf /tmp/orphaned-pkgs

    display_message "[${GREEN}✔${NC}]  Trimming all mount points on SSD"
    sudo fstrim -av

    echo -e "\e[1;32m[✔]\e[0m Restarting kernel tweaks...\n"
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
    sudo sysctl -p

    display_message "[${GREEN}✔${NC}]  Cleanup complete, ENJOY!"
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
}

# Template
# display_message "[${GREEN}✔${NC}]
# display_message "[${RED}✘${NC}]

fix_chrome() {
    display_message "[${GREEN}✔${NC}]  Applying chrome HW accelerations issue for now"
    # Prompt user for reboot or continue
    read -p "Do you want to down grade mesa dlibs now? (y/n): " choice
    case "$choice" in
    y | Y)
        # Apply fix
        display_message "[${GREEN}✔${NC}]  Applied"
        sudo sudo dnf downgrade mesa-libGL
        sudo rm -rf ./config/google-chrome
        sudo rm -rf ./cache/google-chrome
        sudo chmod -R 770 ~/.cache/google-chrome
        sudo chmod -R 770 ~/.config/google-chrome

        sleep 2
        display_message "Bug @ https://bugzilla.redhat.com/show_bug.cgi?id=2193335"
        ;;
    n | N)
        display_message "Fix skipped. Continuing with the script."
        ;;
    *)
        display_message "[${RED}✘${NC}] Invalid choice. Continuing with the script."
        ;;
    esac

    echo "If problems persist, copy and pate the following into chrome address bar and disable HW acceleration"
    echo ""
    echo "chrome://settings/?search=hardware+acceleration"
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
    sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tolgaerok/tolga-scripts/main/Fedora39/execute-python-script.sh)"
}

# Template
# display_message "[${GREEN}✔${NC}]
# display_message "[${RED}✘${NC}]

display_XDG_session() {
    session=$XDG_SESSION_TYPE

    display_message "Current XDG session is [ $session ]"
    echo "Current XDG session is [ $session ]"
    gum spin --spinner dot --title "Stand-by..." -- sleep 2

}

fix_grub() {
    # Check if GRUB_TIMEOUT_STYLE is present
    if ! grep -q '^GRUB_TIMEOUT_STYLE=menu' /etc/default/grub; then
        # Add GRUB_TIMEOUT_STYLE=menu if not present
        echo 'GRUB_TIMEOUT_STYLE=menu' | sudo tee -a /etc/default/grub >/dev/null
    fi

    # Check if UEFI is enabled
    uefi_enabled=$(test -d /sys/firmware/efi && echo "UEFI" || echo "BIOS/Legacy")

    # Display information about GRUB configuration
    display_message "[${GREEN}✔${NC}]  Current GRUB configuration:"
    echo "  - GRUB_TIMEOUT_STYLE: $(grep '^GRUB_TIMEOUT_STYLE' /etc/default/grub | cut -d '=' -f2)"
    echo "  - System firmware: $uefi_enabled"

    # Prompt user to proceed
    read -p "Do you want to proceed with updating GRUB? (yes/no): " choice
    case "$choice" in
    [Yy] | [Yy][Ee][Ss]) ;;
    *)
        echo "GRUB update aborted."
        return
        ;;
    esac

    # Update GRUB configuration
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

    echo "GRUB updated successfully."
}

# Remove KDE Junk
kde_crap() {

    # Color codes
    RED='\e[1;31m'
    GREEN='\e[1;32m'
    YELLOW='\e[1;33m'
    NC='\e[0m' # No Color

    # List of KDE applications to check..
    apps=("akregator" "ksysguard" "dnfdragora" "kfind" "kmag" "kmail"
        "kaddressbook" "kcharselect" "konversation" "elisa-player"
        "kcolorchooser" "kmouth" "korganizer" "kmousetool" "kruler"
        "kmahjongg" "kpat" "kmines" "dragonplayer" "kamoso"
        "kolourpaint" "krdc" "krfb" "kmail-account-wizard"
        "pim-data-exporter" "pim-sieve-editor" "elisa*" "kdeconnectd")

    display_message "Checking for KDE applications..."

    # Check if each application is installed
    found_apps=()
    for app in "${apps[@]}"; do
        if command -v "$app" &>/dev/null; then
            found_apps+=("$app")
        fi
    done

    # Prompt the user to uninstall found applications
    if [ ${#found_apps[@]} -gt 0 ]; then
        clear
        display_message "[${RED}✘${NC}] The following KDE applications are installed:"
        for app in "${found_apps[@]}"; do
            echo -e "  ${RED}[✘]${NC}  ${YELLOW}==>${NC}  $app"
        done

        echo ""
        read -p "Do you want to uninstall them? (y/n): " uninstall_choice
        if [ "$uninstall_choice" == "y" ]; then
            display_message "[${RED}✘${NC}] Uninstalling KDE applications..."

            # Build a string of package names
            packages_to_remove=$(
                IFS=" "
                echo "${found_apps[*]}"
            )

            sudo dnf remove $packages_to_remove

            sudo dnf remove kmail-account-wizard mbox-importer kdeconnect pim-data-exporter elisa*
            dnf clean all

            # Remove media players
            sudo dnf remove -y \
                dragon \
                elisa-player \
                kamoso

            # Remove akonadi
            # sudo dnf remove -y *akonadi*

            # Remove games
            sudo dnf remove -y \
                kmahjongg \
                kmines \
                kpat

            # Remove misc applications
            sudo dnf remove -y \
                dnfdragora \
                konversation \
                krdc \
                krfb \
                plasma-welcome

            read -p "Do you want to perform autoremove? (y/n): " autoremove_choice
            if [ "$autoremove_choice" == "y" ]; then
                sudo dnf remove kmail-account-wizard mbox-importer kdeconnect pim-data-exporter elisa*
                sudo dnf autoremove
                dnf clean all
            fi
            display_message "[${GREEN}✔${NC}]  Uninstallation completed."
        else
            display_message "[${RED}✘${NC}] No applications were uninstalled."
        fi
    else
        sudo dnf remove kmail-account-wizard mbox-importer kdeconnect pim-data-exporter elisa*
        sudo dnf autoremove
        dnf clean all
        display_message "[${GREEN}✔${NC}]  Congratulations, no KDE applications detected."
        sleep 1
    fi
}

# Function to start balance operation
start_balance() {
    display_message "[${GREEN}✔${NC}]  Balance operation started successfully."
    echo -e "\n ${YELLOW}==>${NC} This will take a very LONG time..."
    check_balance_status
    sudo btrfs balance start --full-balance / &
    check_balance_status
    display_message "[${GREEN}✔${NC}]  Balance operation running in background."
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
}

# Function to check balance status
check_balance_status() {
    display_message "[${GREEN}✔${NC}]  Balance operation successfull"
    sudo btrfs balance status /
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
}

# Function to start scrub operation
start_scrub() {
    display_message "[${GREEN}✔${NC}]  Scrub operation started successfully."
    check_scrub_status
    sudo btrfs scrub start /
    check_scrub_status
    display_message "[${GREEN}✔${NC}]  Scrub operation running in background."
    gum spin --spinner dot --title "Stand-by..." -- sleep 4

}

# Function to check scrub status.
check_scrub_status() {
    display_message "[${GREEN}✔${NC}]  Scrub operation successfull"
    sudo btrfs scrub status /
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
}

# Function to display the main menu
btrfs_maint() {

    # Start balance operation
    start_balance

    # Display balance status
    echo -e "\n ${YELLOW}==>${NC} Checking balance status..."
    check_balance_status

    # Start scrub operation
    start_scrub

    # Display scrub status
    echo -e "\n ${YELLOW}==>${NC} Checking scrub status..."
    check_scrub_status

    # Check if both operations have completed
    if ! pgrep -f "sudo btrfs balance start" >/dev/null &&
        ! pgrep -f "sudo btrfs scrub start" >/dev/null; then
        display_message "[${GREEN}✔${NC}]  Balance and scrub operations running in background."
        sleep 5
        break
    fi

    # Sleep for 10 seconds before checking again
    display_message "[${GREEN}✔${NC}]  Balance and scrub operations running in background."
    echo -e "\n ${YELLOW}==> ${NC} BTRFS balance and scrub will take a VERY LONG time ...\n"
    gum spin --spinner dot --title "Stand-by..." -- sleep 7

}

create-extra-dir() {
    display_message "[${GREEN}✔${NC}]  Create extra needed directories"
    # Directories to create
    directories=(
        "${HOME}/.config/autostart"
        "${HOME}/.config/environment.d"
        "${HOME}/.config/systemd/user"
        "${HOME}/.local/bin"
        "${HOME}/.local/share/applications"
        "${HOME}/.local/share/fonts"
        "${HOME}/.local/share/icons"
        "${HOME}/.local/share/themes"
        "${HOME}/.ssh"
        "${HOME}/.zshrc.d"
        "${HOME}/Applications"
        "${HOME}/src"
    )

    # Create directories
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        gum spin --spinner dot --title "[✔]  Creating: $dir" -- sleep 1
        sleep 0.5
    done

    # Set SSH folder permissions
    chmod 700 ${HOME}/.ssh

    display_message "[${GREEN}✔${NC}]  Extra hidden dirs created"
    gum spin --spinner dot --title "Stand-by..." -- sleep 2

}

speed-up-shutdown() {
    display_message "${YELLOW}[*]${NC} Configure shutdown of units and services to 10s .."
    sleep 1

    # Configure default timeout to stop system units
    sudo mkdir -p /etc/systemd/system.conf.d
    sudo tee /etc/systemd/system.conf.d/default-timeout.conf <<EOF
[Manager]
DefaultTimeoutStopSec=10s
EOF

    # Configure default timeout to stop user units
    sudo mkdir -p /etc/systemd/user.conf.d
    sudo tee /etc/systemd/user.conf.d/default-timeout.conf <<EOF
[Manager]
DefaultTimeoutStopSec=10s
EOF

    display_message "${GREEN}[✔]${NC} Shutdown speed configured"
    gum spin --spinner dot --title "Stand-by..." -- sleep 2

}

check_internet_connection() {
    display_message "${YELLOW}[*]${NC} Checking Internet Connection .."
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
    display_message "${GREEN}[✔]${NC} connecting to google.."

    if curl -s -m 10 https://www.google.com >/dev/null || curl -s -m 10 https://www.github.com >/dev/null; then
        display_message "${GREEN}[✔]${NC} Network connection is OK "
        gum spin --spinner dot --title "Stand-by..." -- sleep 2
    else
        display_message "${RED}[✘]${NC} Network connection is not available ${RED}[✘]${NC}"
        gum spin --spinner dot --title "Stand-by..." -- sleep 2
    fi

    echo ""

    echo -e "${YELLOW}[*]${NC} Executing menu ..."
    gum spin --spinner dot --title "Stand-by..." -- sleep 2
    clear
}

firewall() {
    # Define allowed TCP ports
    allowedTCPPorts=(
        21    # FTP
        53    # DNS
        80    # HTTP
        443   # HTTPS
        143   # IMAP
        389   # LDAP
        139   # Samba
        445   # Samba
        25    # SMTP
        22    # SSH
        5432  # PostgreSQL
        3306  # MySQL/MariaDB
        3307  # MySQL/MariaDB
        111   # NFS
        2049  # NFS
        2375  # Docker
        22000 # Syncthing
        9091  # Transmission
        60450 # Transmission
        80    # Gnomecast server
        8010  # Gnomecast server
        8888  # Gnomecast server
        5357  # wsdd: Samba
        1714  # Open KDE Connect
        1764  # Open KDE Connect
        8200  # Teamviewer
    )

    # Define allowed UDP ports
    allowedUDPPorts=(
        53    # DNS
        137   # NetBIOS Name Service
        138   # NetBIOS Datagram Service
        3702  # wsdd: Samba
        5353  # Device discovery
        21027 # Syncthing
        22000 # Syncthing
        8200  # Teamviewer
        1714  # Open KDE Connect
        1764  # Open KDE Connect
    )
    display_message "[${GREEN}✔${NC}] Setting up firewall ports (OLD NixOs settings)"
    gum spin --spinner dot --title "Stand-by..." -- sleep 2

    # Add allowed TCP ports
    for port in "${allowedTCPPorts[@]}"; do
        sudo firewall-cmd --permanent --add-port="$port/tcp"
        gum spin --spinner dot --title "Setting up TCPorts:  $port" -- sleep 0.5
    done

    # Add allowed UDP ports
    for port in "${allowedUDPPorts[@]}"; do
        sudo firewall-cmd --permanent --add-port="$port/udp"
        gum spin --spinner dot --title "Setting up UDPPorts:  $port" -- sleep 0.5
    done

    # Add extra command for NetBIOS name resolution traffic on UDP port 137
    display_message "[${GREEN}✔${NC}] Adding NetBIOS name resolution traffic on UDP port 137"
    gum spin --spinner dot --title "Add extra command for NetBIOS name resolution traffic on UDP port 137" -- sleep 1.5
    sudo iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns

    # Reload the firewall for changes to take effect
    sudo firewall-cmd --reload
    gum spin --spinner dot --title "Reloading firewall" -- sleep 0.5

    display_message "[${GREEN}✔${NC}] Firewall rules applied successfully."
    gum spin --spinner dot --title "Reloading MainMenu" -- sleep 1.5
}

# Template
# display_message "[${GREEN}✔${NC}]
# display_message "[${RED}✘${NC}]

update_flatpak() {
    display_message "[${GREEN}✔${NC}]  Updating Flatpak..."

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    # flatpak update
    flatpak update -y

    display_message "[${GREEN}✔${NC}]  Executing Brians's Flatpak's..."

    flatpak override --env=GTK_MODULES=colorreload-gtk-module org.mozilla.firefox

    # Execute the Flatpak Apps installation script from the given URL
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/wvpianoman/brian-scripts/main/solus/FlatPakInstall.sh)"

    display_message "[${GREEN}✔${NC}]  Flatpak updated successfully."

    # Call the cleanup function
    cleanup_flatpak_cruft
}

# Function to display the main menu.
display_main_menu() {
    clear
    echo -e "\n                  Tolga's online Fedora updater\n"
    echo -e "\e[34m|--------------------------|\e[33m Main Menu \e[34m |-------------------------------------|\e[0m"
    echo -e "\e[33m 1.\e[0m \e[32m \e[0m"
    echo -e "\e[33m 2.\e[0m \e[32m \e[0m"
    echo -e "\e[33m 3.\e[0m \e[32m Update the system                                            ( Create meta cache etc )\e[0m"
    echo -e "\e[33m 4.\e[0m \e[32m Install firmware updates                                     ( Not compatible with all systems )\e[0m"
    echo -e "\e[9m 5. \e[0m \e[32m \e[0m"
    echo -e "\e[33m 6.\e[0m \e[32m Optimize battery life\e[0m"
    echo -e "\e[9m 7\e[0m.\e[9m \e[32mInstall multimedia codecs                                          \e[0m"
    echo -e "\e[33m 8.\e[0m \e[32m Install H/W Video Acceleration for AMD or Intel\e[0m"
    echo -e "\e[33m 9.\e[0m \e[32m Update Flatpak\e[0m"
    echo -e "\e[33m 10.\e[0m \e[32mSet UTC Time\e[0m"
    echo -e "\e[33m 11.\e[0m \e[32m \e[0m"
    echo -e "\e[33m 12.\e[0m \e[32mEnable Modern Standby\e[0m"
    echo -e "\e[33m 13.\e[0m \e[32mEnable nvidia-modeset\e[0m"
    echo -e "\e[33m 14.\e[0m \e[32mDisable NetworkManager-wait-online.service\e[0m"
    echo -e "\e[33m 15.\e[0m \e[32mDisable Gnome Software from Startup Apps\e[0m"
    echo -e "\e[33m 16.\e[0m \e[32mChange hostname                                              ( Change current localname/pc name )\e[0m"
    echo -e "\e[33m 17.\e[0m \e[32m \e[0m"
    echo -e "\e[33m 18.\e[0m \e[32mInstall additional apps\e[0m"
    echo -e "\e[33m 19.\e[0m \e[32mCleanup Fedora\e[0m"
    echo -e "\e[33m 20.\e[0m \e[32mFix Chrome HW accelerations issue                            ( No guarantee )\e[0m"
    echo -e "\e[33m 21.\e[0m \e[32mDisplay XDG session\e[0m"
    echo -e "\e[33m 22.\e[0m \e[32mFix grub or rebuild grub                                     ( Checks and enables menu output to grub menu )\e[0m"
    echo -e "\e[33m 23.\e[0m \e[32m \e[0m"
    echo -e "\e[33m 24.\e[0m \e[32mRemove KDE bloatware                                         ( Why are these installed? )\e[0m"
    echo -e "\e[33m 25.\e[0m \e[32mPerform BTRFS balance and scrub operation on / partition     ( !! WARNING, backup important data incase, 5 min operation )\e[0m"
    echo -e "\e[33m 26.\e[0m \e[32mCreate extra hidden dir in HOME                                "
    echo -e "\e[33m 27.\e[0m \e[32mModify systemd timeout settings to 10s                         "
    echo -e "\e[33m 28.\e[0m \e[32mSet-up TCP && UDP firewall settings                          ( Mimic my NixOS firewall settings )                         "
    echo -e "\e[34m|-------------------------------------------------------------------------------|\e[0m"
    echo -e "\e[31m   (0) \e[0m \e[32mExit\e[0m"
    echo -e "\e[34m|-------------------------------------------------------------------------------|\e[0m"
    echo ""

}

# Function to handle user input
handle_user_input() {

    # Get the hostname and username
    hostname=$(hostname)
    username=$(whoami)

    echo -e "${YELLOW}┌──($username㉿$hostname)-[$(pwd)]${NC}"

    choice=""
    echo -n -e "${YELLOW}└─\$>>${NC} "
    read choice

    echo ""

    case "$choice" in
    1)  ;;
    2)  ;;
    3) update_system ;;
    4) install_firmware ;;
    5)  ;;
    6) optimize_battery ;;
    7) install_multimedia_codecs ;;
    8) install_hw_video_acceleration_amd_or_intel ;;
    9) update_flatpak ;;
    10) set_utc_time ;;
    11)  ;;
    12) enable_modern_standby ;;
    13) enable_nvidia_modeset ;;
    14) disable_network_manager_wait_online ;;
    15) disable_gnome_software_startup ;;
    16) change_hotname ;;
    17) check_mitigations_grub ;;
    18) install_apps ;;
    19) cleanup_fedora ;;
    20) fix_chrome ;;
    21) display_XDG_session ;;
    22) fix_grub ;;
    23)  ;;
    24) kde_crap ;;
    25) btrfs_maint ;;
    26) create-extra-dir ;;
    27) speed-up-shutdown ;;
    28) firewall ;;

    0)
        # Before exiting, check if duf and neofetch are installed
        for_exit "duf"
        for_exit "neofetch"
        for_exit "figlet"
        for_exit "espeak"
        duf
        neofetch
        figlet Solus Linux
        #end_time=$(date +%s)
        #time_taken=$((end_time - start_time))
        # # espeak -v en-us+m7 -s 165 "ThankYou! For! Using! My Configurations! Bye! "
        exit
        ;;
    *)
        echo -e "Invalid choice. Please enter a number from 0 to 28."
        gum spin --spinner dot --title "Stand-by..." -- sleep 1
        ;;
    esac
}

check_internet_connection

# Main loop for the menu
while true; do
    display_main_menu
    handle_user_input
done

