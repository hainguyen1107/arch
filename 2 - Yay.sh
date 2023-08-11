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

    'gedit'                   # Text editor
    'nano'                    # Text editor

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

    'mpv'              # MPV player
    'goldendict-nggit'	    # Golden dictionary	
    'okular'                # PDF viewer
    'libreoffice-fresh'     # Office
    'all-repository-fonts'  # Fonts
    'google-chrome'	    # Web browser
    'ferdium-bin'	    # Messenger, discord... manager
    'ibus-bamboo'	    # Vietnamese IME for Ibus
    'xorg-fonts-misc-otb'   # Xorg misc fonts

)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    yay -Syu "$PKG" --noconfirm --needed
done


echo
echo "Done!"
echo


