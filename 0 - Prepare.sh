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

echo "Prepare some important variables"
mkdir variables
lsblk
echo "Please enter disk: (example /dev/sda)"
read X
echo $X > variables/disk
echo "How large your swap partition is (Gigabyte):"
read X
echo $X > variables/swap
echo "Please enter your hostname: (example dopamine)"
read X
echo $X > variables/hostname
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
sgdisk -n 1:0:+512M $(cat "variables/disk") # partition 1 (UEFI SYS), default start block, 512MB
sgdisk -n 2:0:+550M $(cat "variables/disk") # Partition 2 (XBOOTLDR), A separate /boot partition to keep kernel and initframf separate from the ESP, 550MB
sgdisk -n 3:0:+$(cat "variables/swap")G  $(cat "variables/disk") # partition 2 (Swap)
sgdisk -n 4:0:0     $(cat "variables/disk") # partition 3 (Root), default start, remaining

# set partition types
sgdisk -t 1:ef00 $(cat "variables/disk")
sgdisk -t 2:ea00 $(cat "variables/disk")
sgdisk -t 3:8200 $(cat "variables/disk")
sgdisk -t 4:8304 $(cat "variables/disk")

# label partitions
sgdisk -c 1:"ESP" $(cat "variables/disk")
sgdisk -c 2:"XBOOTLDR" $(cat "variables/disk")
sgdisk -c 3:"SWAP" $(cat "variables/disk")
sgdisk -c 4:"ROOT" $(cat "variables/disk")

# Wipe all partitions
wipefs -a "$(cat "variables/disk")p1"
wipefs -a "$(cat "variables/disk")p2"
wipefs -a "$(cat "variables/disk")p3"
wipefs -a "$(cat "variables/disk")p4"

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "ESP" "$(cat "variables/disk")p1"
mkfs.vfat -F32 -n "XBOOTLDR" "$(cat "variables/disk")p2"
mkswap -L "SWAP" "$(cat "variables/disk")p3"
swapon "$(cat "variables/disk")p3"
mkfs.ext4 -L "ROOT" "$(cat "variables/disk")p4"

# mount target
mount -t ext4 "$(cat "variables/disk")p4" /mnt
mkdir -p /mnt/efi
mkdir -p /mnt/boot
mount -t vfat "$(cat "variables/disk")p1" /mnt/efi
mount -t vfat "$(cat "variables/disk")p2" /mnt/boot

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

echo "--------------------------------------"
echo "-- Bootloader Systemd Installation  --"
echo "--------------------------------------"

arch-chroot /mnt pacman -Syu --needed --noconfirm efibootmgr intel-ucode
bootctl --esp-path=/mnt/efi --boot-path=/mnt/boot install

cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=$(cat "variables/disk")p4 rw lsm=landlock,lockdown,yama,integrity,apparmor,bpf
EOF

cat <<EOF > /mnt/efi/loader/loader.conf
default arch
timeout 3
console-mode keep
editor no
EOF

# Set timezone
timedatectl --no-ask-password set-timezone Asia/Ho_Chi_Minh
# Enable Network Time Sync
timedatectl --no-ask-password set-ntp true
# Sync local time with hardware clock
timedatectl set-local-rtc true

# Set keymaps
localectl --no-ask-password set-keymap us

#Set language
printf "en_US.UTF-8 UTF-8\n" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
printf "LANG=en_US.UTF-8\n" > /mnt/etc/locale.conf

#Set hostname
hostnamectl --no-ask-password set-hostname $(cat "variables/hostname")
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

    # --- Disk utilities
         'gparted'                          # Disk utility
         'ntfs-3g'                          # Open source implementation of NTFS file system
         'parted'                           # Disk utility

    # --- Setup Desktop KDE Plasma
        'plasma-meta'                       # KDE Plasma
        'plasma-wayland-session'            # Enable Wayland for KDE Plasma
        'plymouth-kcm'                      # KCM to manage the Plymouth (Boot) theme
        'konsole'                           # KDE terminal emulator
        'yakuake'                           # KDE top-down terminal
        'ark'                               # KDE Plasma archiver
        'latte-dock'                        # A dock based on Plasma Frameworks
        'conky'                             # Lightweight system monitor
        'dolphin'                           # KDE File Manager
        'dolphin-plugins'                   # Extra Dolphin plugins
        'bluedevil'                         # KDE bluetooth stack
        'flameshot'                         # Screenshoot
        'kcalc'                             # KDE calculator

    # --- Thumbnail generation
        'kdegraphics-thumbnailers'          # Thumbnailers for various graphics file formats
        'ffmpegthumbs'                      # FFmpeg-based thumbnail creator for video files
        
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
Target=nvidia-dkms
Target=linux

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case \$trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF

cat > /mnt/etc/pacman.d/hooks/refind.hook << EOF
[Trigger]
Operation=Upgrade
Type=Package
Target=refind

[Action]
Description = Updating rEFInd on ESP
When=PostTransaction
Exec=/usr/bin/refind-install
EOF

# Regenerate mkinitcpio
arch-chroot /mnt mkinitcpio -P

# Enable SDDM! Ready to reboot into KDE Plasma
arch-chroot /mnt systemctl enable sddm.service

# Enable systemd-boot-update-service
arch-chroot /mnt systemctl enable systemd-boot-update.service

chmod +x 1\ -\ Post-install.sh
mv 1\ -\ Post-install.sh /mnt/home/$(cat "variables/username")


echo "--------------------------------------"
echo "--   SYSTEM READY FOR FIRST BOOT    --"
echo "--------------------------------------"
