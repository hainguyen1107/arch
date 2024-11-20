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
curl -s "https://archlinux.org/mirrorlist/?country=SG&country=VN&protocol=http&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 -m 3 - > /etc/pacman.d/mirrorlist

echo -e "\nInstalling prereqs...\n"
pacman -S --noconfirm --needed gptfdisk

echo "Prepare some important variables"
mkdir variables
lsblk
echo "Please enter disk: (example /dev/sda)"
read X
echo $X > variables/disk
echo "How large your swap partition is (Gigabyte):"
read X
echo $X > variables/swap
echo "How large your windows partition is (Gigabyte):"
read X
echo $X > variables/windows
echo "Please enter your hostname: (example dopamine)"
read X
echo $X > variables/hostname
echo "How large your Linux partition is (Gigabyte):"
read X
echo $X > variables/linux
echo "Please enter your username: (example serotonin)"
read X
echo $X > variables/username
echo "Please enter your nickname: (example acetylcholine)"
read X
echo $X > variables/nickname
echo "Please enter your temporary password:"
read X
echo $X > variables/password

# disk preparation
sgdisk -Z $(cat "variables/disk") # zap all on disk
sgdisk -a 4096 -o $(cat "variables/disk") # new gpt disk 4096 alignment

# create partitions
sgdisk -n 1:0:+550M $(cat "variables/disk") # partition 1 (UEFI SYS), default start block, 550MB
sgdisk -n 2:0:+550M $(cat "variables/disk") # partition 2 (XBOOTLDR), default start block, 550MB
sgdisk -n 3:0:+$(cat "variables/swap")G  $(cat "variables/disk") # partition 2 (Swap)
sgdisk -n 4:0:+$(cat "variables/windows")G  $(cat "variables/disk") # partition 3 (Windows)
sgdisk -n 5:0:+$(cat "variables/linux")G  $(cat "variables/disk") # partition 4 (Root)
sgdisk -n 6:0:0  $(cat "variables/disk") # partition 6 (DATA)

# set partition types
sgdisk -t 1:ef00 $(cat "variables/disk")
sgdisk -t 2:ea00 $(cat "variables/disk")
sgdisk -t 3:8200 $(cat "variables/disk")
sgdisk -t 4:0700 $(cat "variables/disk")
sgdisk -t 5:8300 $(cat "variables/disk")
sgdisk -t 6:0700 $(cat "variables/disk")

# label partitions
sgdisk -c 1:"ESP" $(cat "variables/disk")
sgdisk -c 2:"XBOOTLDR" $(cat "variables/disk")
sgdisk -c 3:"SWAP" $(cat "variables/disk")
sgdisk -c 4:"WINDOWS" $(cat "variables/disk")
sgdisk -c 5:"ROOT" $(cat "variables/disk")
sgdisk -c 6:"DATA" $(cat "variables/disk")

# Wipe all partitions
wipefs -a "$(cat "variables/disk")p1"
wipefs -a "$(cat "variables/disk")p2"
wipefs -a "$(cat "variables/disk")p3"
wipefs -a "$(cat "variables/disk")p4"
wipefs -a "$(cat "variables/disk")p5"
wipefs -a "$(cat "variables/disk")p6"

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "ESP" "$(cat "variables/disk")p1"
mkfs.vfat -F32 -n "XBOOTLDR" "$(cat "variables/disk")p2"
mkswap -L "SWAP" "$(cat "variables/disk")p3"
swapon "$(cat "variables/disk")p3"
mkfs.ntfs -L "WINDOWS" -f "$(cat "variables/disk")p4"
mkfs.ext4 -L "ROOT" "$(cat "variables/disk")p5"
mkfs.ntfs -L "DATA" -f "$(cat "variables/disk")p6"

# mount target
mount -t ext4 "$(cat "variables/disk")p5" /mnt
mkdir -p /mnt/efi
mount -t vfat "$(cat "variables/disk")p1" /mnt/efi
mkdir -p /mnt/boot
mount -t vfat "$(cat "variables/disk")p2" /mnt/boot
mkdir -p /mnt/DATA
blkid "$(cat "variables/disk")p5" | grep -Po ' UUID="\K[^"]*' > variables/uuid
blkid "$(cat "variables/disk")p6" | grep -Po ' UUID="\K[^"]*' > variables/uuid_data

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"

# Set up pacman.conf for faster downloading and more colorful
sed -i 's/#Parallel/Parallel/' /etc/pacman.conf
sudo sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i '/Color/a ILoveCandy' /etc/pacman.conf

# Install base packages
pacstrap /mnt base base-devel linux linux-headers linux-firmware man-pages man-db iptables-nft networkmanager --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab
sed -i 's/ntfs/ntfs-3g/' /mnt/etc/fstab

echo "--------------------------------------"
echo "-- Bootloader Systemd Installation  --"
echo "--------------------------------------"

arch-chroot /mnt pacman -Syu --needed --noconfirm efibootmgr intel-ucode

# Set keymaps
localectl --no-ask-password set-keymap us

#Set language
printf "en_US.UTF-8 UTF-8\n" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
printf "LANG=en_US.UTF-8\n" > /mnt/etc/locale.conf

#Set hostname
echo $(cat "variables/hostname") > /mnt/etc/hostname
printf "127.0.0.1\tlocalhost\n" >> /mnt/etc/hosts
printf "::1\tlocalhost\n" >> /mnt/etc/hosts
printf "127.0.0.1\t$(cat "variables/hostname").localdomain\t$(cat "variables/hostname")\n" >> /mnt/etc/hosts
arch-chroot /mnt systemctl enable NetworkManager

# Set new user
arch-chroot /mnt useradd -mU -s /bin/bash -G lp,optical,wheel,uucp,disk,power,video,audio,storage,games,input $(cat "variables/username") -d /home/$(cat "variables/username") -c "$(cat "variables/nickname")"
echo "$(cat "variables/username"):$(cat "variables/password")" | chpasswd --root /mnt

# Set password for root
echo "root:$(cat "variables/password")" | chpasswd --root /mnt

# Add sudo right for user and remove password timeout
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
echo "Defaults timestamp_timeout=-1" >> /mnt/etc/sudoers

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/#//' /mnt/etc/pacman.conf

# Set up pacman.conf for faster downloading for new system
sed -i 's/#Parallel/Parallel/' /mnt/etc/pacman.conf
sed -i 's/#Color/Color/' /mnt/etc/pacman.conf
sed -i '/Color/a ILoveCandy' /mnt/etc/pacman.conf

# Install essential packages
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
        'nvidia'                        # NVIDIA drivers for linux
        'lib32-nvidia-utils'            # NVIDIA drivers utilities (32-bit)
        'nvidia-utils'                  # NVIDIA drivers utilities
        'opencl-nvidia'                 # OpenCL implemention for NVIDIA
        'lib32-opencl-nvidia'           # OpenCL implemention for NVIDIA (32-bit)
        'nvidia-settings'               # Tool for configuring the NVIDIA graphics driver
        
    # --- Git
        'git'                           # The fast distributed version control system, git 

    # --- ZSH
        'zsh'                           # A very advanced and programmable command interpreter (shell) for UNIX
        'zsh-completions'               # Additional completion definitions for Zsh
        'zsh-autosuggestions'           # Fish-like autosuggestions for zsh
        'zsh-syntax-highlighting'       # Fish shell like syntax highlighting for Zsh
     
    # --- Audio
        'sof-firmware'                  # Sound Open Firmware
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
        'gnome'                 		         # Gnome Desktop
        'gnome-tweaks'          		         # Graphical tools for gnome
        'endeavour'             		         # Gnome personal task manager
        'gedit'                 		         # Gnome text editor
        'file-roller'           		         # Create/modify archives
        'gnome-sound-recorder'  		         # Utility for recording sound 
        'seahorse'              		         # GNOME application for managing PGP keys
        'gnome-terminal'        		         # Terminal
        'gnome-themes-extra'    		         # Extra themes
        'gnome-video-effects'   		         # Video effects
        'gnome-usage'				               # Show usage
        'gnome-todo' 				               # To-do list
        'gnome-shell-extension-appindicator' 	# Modification for shell
        'gedit-plugins'  			             # Plugins for gedit
        'alacarte'
        'gnome-bluetooth-3.0'	             # Gnome bluetooth

    # --- Disk utilities
         'gparted'                          # Disk utility
         'ntfs-3g'                          # Open source implementation of NTFS file system
         'parted'                           # Disk utility

    # --- Setup Desktop KDE Plasma
    #    'plasma-meta'                       # KDE Plasma
    #    'plasma-wayland-session'            # Enable Wayland for KDE Plasma
    #    'plymouth-kcm'                      # KCM to manage the Plymouth (Boot) theme
    #    'konsole'                           # KDE terminal emulator
    #    'yakuake'                           # KDE top-down terminal
    #    'ark'                               # KDE Plasma archiver
    #    'conky'                             # Lightweight system monitor
    #    'dolphin'                           # KDE File Manager
    #    'dolphin-plugins'                   # Extra Dolphin plugins
    #    'bluedevil'                         # KDE bluetooth stack
    #    'flameshot'                         # Screenshoot
    #    'kcalc'                             # KDE calculator

    # --- Thumbnail generation
    #    'kdegraphics-thumbnailers'          # Thumbnailers for various graphics file formats
    #    'ffmpegthumbs'                      # FFmpeg-based thumbnail creator for video files
        
    # --- Networking Setup
        'dialog'                    		    # Enables shell scripts to trigger dialog boxex
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

# Install systemd-boot
arch-chroot /mnt bootctl --esp-path=/efi --boot-path=/boot install

# Set up pacman hook for systemd-boot upgrade
cat > /etc/pacman.d/hooks/95-systemd-boot.hook << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOF

# Loader configuration
cat > /mnt/efi/loader/loader.conf << EOF
default  arch.conf
timeout  4
console-mode auto
editor   no
EOF

# Adding loader
cat > /mnt/boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID="$(cat "variables/uuid")" rw
EOF

# Fallback kernel
cat > /mnt/boot/loader/entries/arch-fallback.conf << EOF
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux-fallback.img
options root=UUID="$(cat "variables/uuid")" rw quiet splash
EOF

# Remove kms from the HOOKS array in /etc/mkinitcpio.conf to prevent the initramfs from containing 
# the nouveau module making sure the kernel cannot load it during early boot
sed -i 's/ kms//' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

# Create a hook for NVIDIA Drivers
mkdir -p /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/nvidia.hook << EOF
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case \$trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF

# Add Nvidia parameters for kernel (for hyprland)
sed -i 's/MODULES=(/MODULES=(\ nvidia\ nvidia-drm\ vidia_modeset\ nvidia_uvm\ /g' /mnt/etc/mkinitcpio.conf 
echo "options nvidia_drm modeset=1 fbdev=1" >> /mnt/etc/modprobe.d/nvidia.conf 

# Regenerate mkinitcpio
arch-chroot /mnt mkinitcpio -P

# Enable SDDM! Ready to reboot into KDE Plasma
# arch-chroot /mnt systemctl enable sddm.service

# Enable GDM
arch-chroot /mnt systemctl enable gdm.service


# Mount /DATA
cat > /mnt/etc/fstab << EOF
# $(cat "variables/disk")p6 LABEL=DATA
UUID=$(cat "variables/uuid_data") /DATA ntfs-3g rw,defaults 0 2
EOF

chmod +x 1\ -\ Post-install.sh
mv -r ../arch  /mnt/home/$(cat "variables/username")


# Set timezone
timedatectl set-timezone Asia/Ho_Chi_Minh
# Enable Network Time Sync
timedatectl set-ntp true

echo "--------------------------------------"
echo "--   SYSTEM READY FOR FIRST BOOT    --"
echo "--------------------------------------"
