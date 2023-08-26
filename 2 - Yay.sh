#!/bin/bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

echo
echo "Installing Yay"
echo

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm --needed
cd ~

# Configure audio
echo "Please enter your username!"
read user
cp -r /usr/share/pipewire /home/$user/.config/
sed -i '/resample.quality/s/#//; /resample.quality/s/4/15/' /home/$user/.config/pipewire/{client.conf,pipewire-pulse.conf}

# Install software
PKGS=(

    # TERMINAL UTILITIES --------------------------------------------------

    'neofetch'                # Shows system info when you launch terminal
    'ntp'                     # Network Time Protocol to set time via network.
    'p7zip'                   # 7z compression program
    'terminus-font'           # Font package with some bigger fonts for login terminal
    'unrar'                   # RAR compression program
    'unzip'                   # Zip compression program
    'wget'                    # Remote content retrieval
    'zip'                     # Zip compression program
    'syntax-highlighting'     # Terminal Plugin

    # DEVELOPMENT ---------------------------------------------------------

    'neovim'                   # Text editor

    # KVM/QEMU
    'virt-manager'
    'qemu'
    'vde2'
    'dnsmasq'
    'bridge-utils'
    'virt-viewer'
    'dmidecode'
    'edk2-ovmf'
    'swtpm'

    # OTHERS --------------------------------------------------------

    'mpv'                      # MPV player
    'smplayer'                 # Frontend GUI for mpv player
    'goldendict-nggit'	       # Golden dictionary	
    'okular'                   # PDF viewer
    'libreoffice-fresh'        # Office
    'google-chrome'	           # Web browser
    'ferdium-bin'	           # Messenger, discord... manager
    #'ibus-bamboo'	           # Vietnamese IME for Ibus
    'xorg-fonts-misc-otb'      # Xorg misc fonts
    'nomacs'                   # Image viewer
    
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    yay -Syu "$PKG" --noconfirm --needed
done

# Set up alias for updating (less effort, less typo)
echo "alias up=yay -Syu --noconfirm --needed; yay -Sc --noconfirm" >> ~/.bashrc


echo
echo "Done!"
echo


