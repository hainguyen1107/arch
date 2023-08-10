#!/bin/bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Add sudo right for user
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "Defaults timestamp_timeout=-1" >> /etc/sudoers

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# Install base packages
PKGS=(

    # --- XORG Display Rendering
        'xorg-server'           		# XOrg server
        
    # --- Intel grapgical driver
    	'mesa'
    	'vulkan-intel'
    	'vulkan-icd-loader'			# To run vulkan applications
    	'intel-media-driver'			# For hardware video acceleration in Gen9
    	'intel-compute-runtime'			# Neo OpenCL runtime, the open-source implementation for Intel HD Graphics GPU on Gen8+
    	'ocl-icd'				# OpenCL ICD loader
    	'libva-utils'				# Hardware accelerated MPEG-2 decoding
     
    # --- Audio
        'wireplumber'
    	'pipewire'				# Pirewire
    	'pipewire-pulse'	
    	'pipewire-alsa'
        'alsa-utils'        			# Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
        'alsa-plugins'      			# ALSA plugins
        'xdg-desktop-portal-gtk'
        'gst-plugin-pipewire'
    	
    # --- Setup Desktop
        'gnome'                 		# Gnome Desktop
        'gnome-tweaks'          		# Graphical tools for gnome
        'endeavour'             		# Gnome personal task manager
        'gedit'                 		# Gnome text editor
        'file-roller'           		# Create/modify archives
        'gnome-sound-recorder'  		# Utility for recording sound 
        'seahorse'              		# GNOME application for managing PGP keys
        'gnome-terminal'        		# Terminal
        'gnome-themes-extra'    		# Extra themes
        'gnome-video-effects'   		# Video effects
        'gnome-usage'				# Show usage
        'gnome-todo' 				# To-do list
        'gnome-shell-extension-appindicator' 	# Modification for shell
        'gedit-plugins'  			# Plugins for gedit
        'alacarte'

    # --- Networking Setup
        'dialog'                    		# Enables shell scripts to trigger dialog boxex
        'openvpn'                   		# Open VPN support
        'networkmanager-openvpn'    		# Open VPN plugin for NM
        'network-manager-applet'    		# System tray icon/utility for network connectivity
        'dhclient'                  		# DHCP client
        'libsecret'                 		# Library for storing passwords
        'fail2ban'                  		# Ban IP's after man failed login attempts
        'ufw'                       		# Uncomplicated firewall


    # --- Bluetooth
        'bluez'                 		# Daemons for the bluetooth protocol stack
        'bluez-utils'           		# Bluetooth development and debugging utilities
        'blueberry'             		# Bluetooth configuration tool
        'gnome-bluetooth-3.0'	
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    pacman -Sy "$PKG" --noconfirm --needed
done

# Configure audio
echo "Please enter your username!"
read user
mkdir -p /home/$user/.config/pipewire
cp -r /usr/share/pipewire /home/$user/.config/pipewire
sed -i '/resample.quality/s/#//; /resample.quality/s/4/15/' /home/$user/.config/pipewire/{client.conf,pipewire-pulse.conf}

echo
echo "Done!"
echo
