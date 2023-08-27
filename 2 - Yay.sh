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
cp -r /usr/share/pipewire /home/$(whoami)/.config/
sed -i '/resample.quality/s/#//; /resample.quality/s/4/15/' /home/$(whoami)/.config/pipewire/{client.conf,pipewire-pulse.conf}

# Install software
PKGS=(

    # TERMINAL UTILITIES --------------------------------------------------

    'neofetch'                     # Shows system info when you launch terminal
    'ntp'                          # Network Time Protocol to set time via network.
    'p7zip'                        # 7z compression program
    'terminus-font'                # Font package with some bigger fonts for login terminal
    'unrar'                        # RAR compression program
    'unzip'                        # Zip compression program
    'wget'                         # Remote content retrieval
    'zip'                          # Zip compression program
    'syntax-highlighting'          # Terminal Plugin

    # DEVELOPMENT ---------------------------------------------------------

    'neovim'                       # Text editor

    # KVM/QEMU
    'virt-manager'                 # Desktop user interface for managing virtual machines
    'qemu-full'                    # A full QEMU setup
    'edk2-ovmf'                    # TianoCore project to enable UEFI support for Virtual Machines
    'vde2'                         # Virtual Distributed Ethernet for emulators like qemu
    'dnsmasq'                      # Lightweight, easy to configure DNS forwarder and DHCP server
    'iptables-nft'                 # Linux kernel packet control tool (using nft interface)
    'bridge-utils'                 # Utilities for configuring the Linux ethernet bridge
    'virt-viewer'                  # A lightweight interface for interacting with the graphical display of virtualized guest OS
    'dmidecode'                    # Desktop Management Interface table related utilities
    'swtpm'                        # Libtpms-based TPM emulator with socket, character device, and Linux CUSE interface
    'openbsd-netcat'               # TCP/IP swiss army knife. OpenBSD variant.
    'libguestfs'                   # Access and modify virtual machine disk images

    # OTHERS --------------------------------------------------------

    'mpv'                          # MPV player
    'smplayer'                     # Frontend GUI for mpv player
    'goldendict-nggit'	           # Golden dictionary	
    'okular'                       # PDF viewer
    'libreoffice-fresh'            # Office
    'google-chrome'	               # Web browser
    'ferdium-bin'	               # Messenger, discord... manager
    #'ibus-bamboo'	               # Vietnamese IME for Ibus
    'xorg-fonts-misc-otb'          # Xorg misc fonts
    'nomacs'                       # Image viewer
    'kimageformats'                # Image format plugins for Qt5
    'fcitx5-bamboo'                # Bamboo (Vietnamese Input Method) engine support for Fcitx
    'fcitx5-gtk'                   # Fcitx5 gtk im module and glib based dbus client library
    'fcitx5-qt'                    # Fcitx5 Qt Library
    'fcitx5-configtool'            # Configuration Tool for Fcitx5
    'konsave'                      # Import, export, extract KDE Plasma configuration profile
    'ttf-ms-fonts'                 # Core TTF Fonts from Microsoft
    'bdf-unifont'                  # GNU Unifont Glyphs
    'ttf-dejavu'                   # Font family based on the Bitstream Vera Fonts with a wider range of characters
    'ttf-bitstream-vera'           # Bitstream Vera fonts
    'noto-fonts'                   # Google Noto TTF fonts
    'ttf-google-fonts-git'         # TrueType fonts from the Google Fonts project
    'ttf-liberation'               # Font family which aims at metric compatibility with Arial, Times New Roman, and Courier New
    'ttf-jetbrains-mono'           # Typeface for developers, by JetBrains
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    yay -Syu "$PKG" --noconfirm --needed
done

# Enable QEMU connection for virt-manager
sudo systemctl enable libvirtd.service

# Add user into kvm and libvirt groups
sudo usermod -aG kvm,libvirt $(whoami)
sudo systemctl restart libvirtd.service

# Enable trim for improving SSD performance
sudo systemctl enable fstrim.timer

# Set up alias for updating (less effort, less typo)
echo "alias up=yay -Syu --noconfirm --needed; yay -Sc --noconfirm" >> ~/.bashrc

# Set up for Fcitx5
echo "GTK_IM_MODULE=fcitx" >> ~/.bashrc
echo "QT_IM_MODULE=fcitx" >> ~/.bashrc
echo "XMODIFIERS=@im=fcitx" >> ~/.bashrc

echo "Configuring KDE Plasma!!!"
# Disable Recent Documents tracking (sensitive file revealed!)
kwriteconfig5 --file $HOME/.config/kdeglobals --group RecentDocuments --key UseRecent false

# Use Google-chrome browser for http and https URLs.
kwriteconfig5 --file $HOME/.config/kdeglobals --group 'General' --key 'BrowserApplication' 'google-chrome.desktop'

# Use fastest animation speed.
kwriteconfig5 --file $HOME/.config/kwinrc --group Compositing --key 'AnimationSpeed' '0'

# Disable sliding popup effect.
kwriteconfig5 --file $HOME/.config/kwinrc --group Plugins --key 'slidingpopupsEnabled' --type 'bool' 'false'

# Turn off alert noise when AC adapter is unplugged.
kwriteconfig5 --file $HOME/.config/powerdevil.notifyrc --group 'Event/unplugged' --key 'Action' ''

# Turn off alert noise when trash is emptied.
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/Trash: emptied' --key 'Action' ''

# Turn off alert noises for warnings and errors (popup instead).
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/catastrophe' --key 'Action' 'Popup'
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/fatalerror' --key 'Action' 'Popup'
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/messageCritical' --key 'Action' 'Popup'
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/messageInformation' --key 'Action' 'Popup'
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/messageWarning' --key 'Action' 'Popup'
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/messageboxQuestion' --key 'Action' 'Popup'
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/notification' --key 'Action' 'Popup'
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/printerror' --key 'Action' 'Popup'
kwriteconfig5 --file  $HOME/.config/plasma_workspace.notifyrc --group 'Event/warning' --key 'Action' 'Popup'    

# Turn off alerts for console bells.
kwriteconfig5 --file  $HOME/.config/konsole.notifyrc --group 'Event/BellInvisible' --key 'Action' ''
kwriteconfig5 --file  $HOME/.config/konsole.notifyrc --group 'Event/BellVisible' --key 'Action' ''

# Show hidden files
kwriteconfig5 --file $HOME/.config/kdeglobals --group 'KFileDialog Settings' --key 'Show hidden files' true

# Disable kwallet
kwriteconfig5 --file $HOME/.config/kwalletrc --group "Wallet" --key "Enabled" "false"

# Narrower window drop shadows.
kwriteconfig5 --file breezerc --group 'Common' --key 'ShadowSize' 'ShadowSmall'

# Don't show media controls on the lock screen.
kwriteconfig5 --file kscreenlockerrc --group 'Greeter' --group 'LnF' --group 'General' --key 'showMediaControls' --type 'bool' 'false'

# Start desktop with an empty session
kwriteconfig5 --file ksmserverrc --group 'General' --key 'loginMode' 'default'

# Open new documents in tabs.
kwriteconfig5 --file okularpartrc --group 'General' --key 'ShellOpenFileInTabs' --type 'bool' 'true'

# Make yakuake full-width.
kwriteconfig5 --file yakuakerc --group 'Window' --key 'Width' '100'

# Make yakuake animation instant.
kwriteconfig5 --file yakuakerc --group 'Animation' --key 'Frames' '0'

# Yakuake keyboard shortcuts.
# Make it more like tabs in a web browser.
kwriteconfig5 --file yakuakerc --group 'Shortcuts' --key 'next-session' 'Ctrl+PgDown'
kwriteconfig5 --file yakuakerc --group 'Shortcuts' --key 'previous-session' 'Ctrl+PgUp'
kwriteconfig5 --file yakuakerc --group 'Shortcuts' --key 'view-full-screen' 'F11'

# Allow empty clipboard.
kwriteconfig5 --file klipperrc --group 'General' --key 'PreventEmptyClipboard' --type bool 'false'

# Clear history on exit.
kwriteconfig5 --file klipperrc --group 'General' --key 'KeepClipboardContents' --type bool 'false'

echo
echo "Done!"
echo
