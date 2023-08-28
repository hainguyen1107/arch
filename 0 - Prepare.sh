#!/bin/bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download - 5 best"
echo "-------------------------------------------------"

pacman-key --init
pacman-key --populate
pacman -Syyy
pacman -S pacman-contrib --noconfirm --needed
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -s "https://archlinux.org/mirrorlist/?country=KH&country=CN&country=HK&country=JP&country=TW&country=VN&protocol=http&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 -m 3 - > /etc/pacman.d/mirrorlist

echo -e "\nInstalling prereqs...\n"
pacman -S --noconfirm --needed gptfdisk

echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk: (example /dev/sda)"
read DISK
echo "--------------------------------------"
echo -e "\nFormatting disk...\n"
echo "--------------------------------------"

# disk preparation
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 4096 -o ${DISK} # new gpt disk 4096 alignment

# create partitions
sgdisk -n 1:0:+512M ${DISK} # partition 1 (UEFI SYS), default start block, 512MB
sgdisk -n 2:0:+20G  ${DISK} # partition 2 (Swap), 20G
sgdisk -n 3:0:0     ${DISK} # partition 3 (Root), default start, remaining

# set partition types
sgdisk -t 1:ef00 ${DISK}
sgdisk -t 2:8200 ${DISK}
sgdisk -t 3:8304 ${DISK}

# label partitions
sgdisk -c 1:"ESP" ${DISK}
sgdisk -c 2:"SWAP" ${DISK}
sgdisk -c 3:"ROOT" ${DISK}

# Wipe all partitions
wipefs -a "${DISK}1"
wipefs -a "${DISK}2"
wipefs -a "${DISK}3"

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "ESP" "${DISK}1"
mkswap -L "SWAP" "${DISK}2"
swapon "${DISK}2"
mkfs.ext4 -L "ROOT" "${DISK}3"

# mount target
mount -t ext4 "${DISK}3" /mnt
mkdir -p /mnt/boot/efi
mount -t vfat "${DISK}1" /mnt/boot/

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-headers linux-firmware man-pages man-db iptables-nft networkmanager --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "--------------------------------------"
echo "-- Bootloader Systemd Installation  --"
echo "--------------------------------------"

arch-chroot /mnt pacman -Syu --needed --noconfirm efibootmgr intel-ucode
bootctl install --esp-path /mnt/boot

cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=${DISK}3 rw
EOF

cat <<EOF > /mnt/boot/loader/loader.conf
default arch
timeout 5
console-mode keep
editor no
EOF

#Set timezone
timedatectl --no-ask-password set-timezone Asia/Ho_Chi_Minh
timedatectl --no-ask-password set-ntp 1

# Set keymaps
localectl --no-ask-password set-keymap us

#Set language
printf "en_US.UTF-8 UTF-8\n" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
printf "LANG=en_US.UTF-8\n" > /mnt/etc/locale.conf

#Set hostname
echo "Please enter hostname:"
read hostname
hostnamectl --no-ask-password set-hostname $hostname
printf "127.0.0.1\tlocalhost\n" >> /mnt/etc/hosts
printf "::1\tlocalhost\n" >> /mnt/etc/hosts
printf "127.0.0.1\t$hostname.localdomain\t$hostname\n" >> /mnt/etc/hosts
arch-chroot /mnt systemctl enable NetworkManager

# Set new user
echo -e "\nEnter username to be created:\n"
read user
echo -e "\nEnter nickname to be created:\n"
read nickname
echo -e "\nEnter new password for $user:\n"
read uspw
arch-chroot /mnt useradd -mU -s /bin/bash -G lp,optical,wheel,uucp,disk,power,video,audio,storage,games,input $user -d /home/$user -c "$nickname"
echo "$user:$uspw" | chpasswd --root /mnt

# Set password for root
echo -e "\nEnter new password for root:\n"
read rtpw
echo "root:$rtpw" | chpasswd --root /mnt

# Add sudo right for user and remove password timeout
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
echo "Defaults timestamp_timeout=-1" >> /mnt/etc/sudoers

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/#//' /mnt/etc/pacman.conf

# Install base packages
PKGS=(

    # --- XORG Display Rendering 
        'xorg-server'           		    # XOrg server
    
    # --- Intel grapgical driver
    	  'mesa'                          # An open-source implementation of the OpenGL specification                           
        'lib32-mesa'                    # An open-source implementation of the OpenGL specification (32-bit)
        'intel-graphics-compiler'       # Intel Graphics Compiler for OpenCL
    	  'vulkan-intel'                  # Intel's Vulkan mesa driver
        'lib32-vulkan-intel'            # Intel's Vulkan mesa driver (32-bit)
    	  'vulkan-icd-loader'			        # To run vulkan applications
    	  'intel-media-driver'			      # For hardware video acceleration in Gen9
    	  'intel-compute-runtime'			    # Neo OpenCL runtime, the open-source implementation for Intel HD Graphics GPU on Gen8+
    	  'ocl-icd'				                # OpenCL ICD loader
    	  'libva-utils'				            # Hardware accelerated MPEG-2 decoding

    # --- NVIDIA graphical driver
        'egl-wayland'                   # EGLStream-based Wayland external platform
        
    # --- Git
        'git'                           # The fast distributed version control system, git       
     
    # --- Audio
        'wireplumber'                   # Session / policy manager implementation for PipeWire
    	  'pipewire'				              # Pirewire
        'lib32-pipewire'                # Pipewire for multilib support
    	  'pipewire-pulse'	              # Low-latency audio/video router and processor - PulseAudio replacement
        'pipewire-jack'                 # Low-latency audio/video router and processor - JACK support
        'lib32-pipewire-jack'           # For Jack multilib support
    	  'pipewire-alsa'                 # Low-latency audio/video router and processor - ALSA configuration
        'alsa-utils'        			      # Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
        'alsa-plugins'      			      # ALSA plugins
        'xdg-desktop-portal-gtk'        # A backend implementation for xdg-desktop-portal using GTK
        'gst-plugin-pipewire'           # Multimedia graph framework - pipewire plugin
    	
    # --- Setup Desktop GNOME
    #    'gnome'                 		         # Gnome Desktop
    #    'gnome-tweaks'          		         # Graphical tools for gnome
    #    'endeavour'             		         # Gnome personal task manager
    #    'gedit'                 		         # Gnome text editor
    #    'file-roller'           		         # Create/modify archives
    #    'gnome-sound-recorder'  		         # Utility for recording sound 
    #    'seahorse'              		         # GNOME application for managing PGP keys
    #    'gnome-terminal'        		         # Terminal
    #    'gnome-themes-extra'    		         # Extra themes
    #    'gnome-video-effects'   		         # Video effects
    #    'gnome-usage'				               # Show usage
    #    'gnome-todo' 				               # To-do list
    #    'gnome-shell-extension-appindicator' 	# Modification for shell
    #    'gedit-plugins'  			             # Plugins for gedit
    #    'alacarte'
    #    'gnome-bluetooth-3.0'	             # Gnome bluetooth


    # --- Setup Desktop KDE Plasma
        'plasma-meta'                       # KDE Plasma
        'plasma-wayland-session'            # Enable Wayland for KDE Plasma
        'flatpak-kcm'                       # Flatpak Permissions Management KCM
        'plymouth-kcm'                      # KCM to manage the Plymouth (Boot) theme
        'konsole'                           # KDE terminal emulator
        'yakuake'                           # KDE top-down terminal
        'kvantum'                           # SVG-based theme engine for Qt5/6
        'ark'                               # KDE Plasma archiver
        'latte-dock'                        # A dock based on Plasma Frameworks
        'conky'                             # Lightweight system monitor
        'dolphin'                           # KDE File Manager
        'dolphin-plugins'                   # Extra Dolphin plugins
        'bluedevil'                         # KDE bluetooth stack  

    # --- Thumbnail generation
        'kdegraphics-thumbnailers'          # Thumbnailers for various graphics file formats
        'ffmpegthumbs'                      # FFmpeg-based thumbnail creator for video files
        
    # --- Networking Setup
        'dialog'                    		    # Enables shell scripts to trigger dialog boxex
        'openvpn'                   		    # Open VPN support
        'networkmanager-openvpn'    		    # Open VPN plugin for NM
        'network-manager-applet'    		    # System tray icon/utility for network connectivity
        'dhclient'                  		    # DHCP client
        'libsecret'                 		    # Library for storing passwords
        'fail2ban'                  		    # Ban IP's after man failed login attempts
        'ufw'                       		    # Uncomplicated firewall


    # --- Bluetooth     
        'bluez'                 		        # Daemons for the bluetooth protocol stack
        'bluez-utils'           		        # Bluetooth development and debugging utilities
        'blueberry'             		        # Bluetooth configuration tool
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    arch-chroot /mnt pacman -Syu "$PKG" --noconfirm --needed
done
# Enable SDDM! Ready to reboot into KDE Plasma
arch-chroot /mnt systemctl enable sddm.service

echo "--------------------------------------"
echo "--   SYSTEM READY FOR FIRST BOOT    --"
echo "--------------------------------------"
