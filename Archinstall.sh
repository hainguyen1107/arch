#!/bin/bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download - Singapore Only"
echo "-------------------------------------------------"

pacman-key --init
pacman-key --populate
pacman -Syyy
pacman -S pacman-contrib --noconfirm
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -s "https://archlinux.org/mirrorlist/?country=SG&protocol=http&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

echo -e "\nInstalling prereqs...\n$HR"
pacman -S --noconfirm gptfdisk

echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk: (example /dev/sda)"
read DISK
echo "--------------------------------------"
echo -e "\nFormatting disk...\n$HR"
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

# make filesystems
echo -e "\nCreating Filesystems...\n$HR"

mkfs.vfat -F32 "ESP" "${DISK}p1"
mkswap "SWAP" "${DISK}p2"
swapon "${DISK}p2"
mkfs.ext4 -L "ROOT" "${DISK}p3"

# mount target
mkdir /mnt
mount -t ext4 "${DISK}p3" /mnt
mkdir -p /mnt/boot/efi
mount -t vfat "${DISK}p1" /mnt/boot/

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
arch-chroot /mnt bootctl install --esp-path /mnt/boot

cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=${DISK}p3 rw
EOF

cat <<EOF > /mnt/boot/loader/loader.conf
default arch
timeout 5
console-mode keep
editor no
EOF

#Set timezone
timedatectl --no-ask-password set-timezone America/New_York
timedatectl --no-ask-password set-ntp 1

# Set keymaps
localectl --no-ask-password set-keymap us

#Set language
printf “en_US.UTF-8 UTF-8\n” > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
printf “LANG=en_US.UTF-8\n” > /mnt/etc/locale.conf

#Set hostname
echo "Please enter hostname:"
read hostname
hostnamectl --no-ask-password set-hostname $hostname
printf “127.0.0.1\tlocalhost\n” >> /mnt/etc/hosts
printf “::1\tlocalhost\n” >> /mnt/etc/hosts
printf “127.0.0.1\t$hostname.localdomain\t$hostname\n” >> /mnt/etc/hosts
arch-chroot /mnt systemctl enable NetworkManager

# Set new user
echo -e "\nEnter username to be created:\n"
read user
echo -e "\nEnter nickname to be created:\n"
read nickname
echo -e "\nEnter new password for $user:\n"
read uspw
arch-chroot /mnt useradd -mU -s /usr/bin/zsh -G lp,optical,wheel,uucp,disk,power,video,audio,storage,games,input $user -d /home/$user -c "$nickname"
echo "$user:$uspw" | chpasswd --root /mnt

# Set password for root
echo -e "\nEnter new password for root:\n"
read rtpw
echo "root:$password" | chpasswd --root /mnt

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo
echo "Installing Base System"
echo
PKGS=(

    # --- XORG Display Rendering
        'xorg-server'           		# XOrg server
        
    # --- Intel grapgical driver
    	'mesa'
    	'lib32-mesa'
    	'vulkan-intel'
    	'lib32-vulkan-intel'
    	'vulkan-icd-loader'			# To run vulkan applications
    	'lib32-vulkan-icd-loader'		# To run 32-bit vulkan applications
    	'intel-media-driver'			# For hardware video acceleration in Gen9
    	'intel-compute-runtime'			# Neo OpenCL runtime, the open-source implementation for Intel HD Graphics GPU on Gen8+
    	'ocl-icd'				# OpenCL ICD loader
    	'libva-utils'				# Hardware accelerated MPEG-2 decoding
    	
    # --- Setup Desktop
        'gnome'                 		# Gnome Desktop
        'gnome-tweaks'          		# Graphical tools for gnome
        'endeavour'             		# Gnome personal task manager
        'gedit'                 		# Gnome text editor
        'file-roller'           		# Create/modify archives
        'gnome-sound-recorder'  		# Utility for recording sound 
        'seahorse'              		# GNOME application for managing PGP keys
        'gnome-screenshot '     		# Take screenshot
        'gnome-terminal'        		# Terminal
        'gnome-themes-extra'    		# Extra themes
        'gnome-video-effects'   		# Video effects
        'gnome-usage'				# Show usage
        'gnome-todo' 				# To-do list
        'gnome-shell-extension-appindicator' 	# Modification for shell
        'gedit-plugins'  			# Plugins for gedit
        'alacarte'

    # --- Networking Setup
        'dialog'                    # Enables shell scripts to trigger dialog boxex
        'openvpn'                   # Open VPN support
        'networkmanager-openvpn'    # Open VPN plugin for NM
        'network-manager-applet'    # System tray icon/utility for network connectivity
        'dhclient'                  # DHCP client
        'libsecret'                 # Library for storing passwords
        'fail2ban'                  # Ban IP's after man failed login attempts
        'ufw'                       # Uncomplicated firewall
    
    # --- Audio
    	'pipewire'			# Pirewire
    	'pipewire-pulse'	
    	'lib32-pipewire'
    	'pipewire-alsa'
        'alsa-utils'        		# Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
        'alsa-plugins'      		# ALSA plugins
        'pulseaudio'        		# Pulse Audio sound components
        'xdg-desktop-portal-gtk'
        'gst-plugin-pipewire'
        'wireplumber'

    # --- Bluetooth
        'bluez'                 # Daemons for the bluetooth protocol stack
        'bluez-utils'           # Bluetooth development and debugging utilities
        'blueberry'             # Bluetooth configuration tool
        'gnome-bluetooth-3.0'	
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    arch-chroot /mnt pacman -S "$PKG" --noconfirm --needed
done
echo
echo "Done!"
echo


arch-chroot /mnt

echo "--------------------------------------"
echo "--   SYSTEM READY FOR FIRST BOOT    --"
echo "--------------------------------------"

