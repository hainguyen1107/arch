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

# Enable ibus-bamboo
echo "Enter your username!"
read user
sudo chmod +x /home/$user/.config/
ibus restart
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'Bamboo')]"
gsettings set org.gnome.desktop.interface gtk-im-module "'ibus'"

echo "=== === === Congifuring Gnome === === ==="
# show battery percentage
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    
# disable touchpad
    gsettings set org.gnome.desktop.peripherals.touchpad send-events "'disabled'"
    
# disable two-finger-scrolling touchpad
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
    
# enable edge-scrolling touchpad
    gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false

# enable touchpad tap-to-click
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false

# set touchpad speed
    gsettings set org.gnome.desktop.peripherals.touchpad speed 0.51470588235294112

# enable Night Light
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 18.1
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 18
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 5000
    
# show weekday
    gsettings set org.gnome.desktop.interface clock-show-weekday true

# show date
    gsettings set org.gnome.desktop.interface clock-show-date true
    
# show week number
    gsettings set org.gnome.desktop.calendar show-weekdate true

# disable suspend
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type "'nothing'"
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "'nothing'"

# set default folder viewer nautilus
    gsettings set org.gnome.nautilus.preferences default-folder-viewer "'list-view'"

# set default-zoom-level
    gsettings set org.gnome.nautilus.list-view default-zoom-level "'large'"

# empty favorite-apps
    gsettings set org.gnome.shell favorite-apps "[]"
    
# switch applications only in current workspace
    gsettings set org.gnome.shell.app-switcher current-workspace-only true

# set nautilus initial-size
    gsettings set org.gnome.nautilus.window-state initial-size "(1169, 785)"

# Configure KVM/QEMU
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo sed -i "/^#unix_sock_group = \"libvirt\"$/s/^#//" /etc/libvirt/libvirtd.conf
sudo sed -i "/^#unix_sock_rw_perms = \"0770\"$/s/^#//" /etc/libvirt/libvirtd.conf
sudo gpasswd -a $(whoami) libvirt
sudo gpasswd -a $(whoami) kvm    

# Enable gdm for Gnome
sudo systemctl enable gdm.service

# Enable bluetooth
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service

echo
echo "Done!"
echo


