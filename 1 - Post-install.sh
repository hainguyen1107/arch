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

# Set timezone
timedatectl set-timezone Asia/Ho_Chi_Minh
# Enable Network Time Sync
timedatectl set-ntp true

# Configure audio
cp -r /usr/share/pipewire /home/$(whoami)/.config/
sed -i '/resample.quality/s/#//; /resample.quality/s/4/15/' /home/$(whoami)/.config/pipewire/{client.conf,pipewire-pulse.conf}

# Install software
PKGS=(

    # TERMINAL UTILITIES --------------------------------------------------

    'fastfetch'                    # Like Neofetch, but much faster because written in C
    'ntp'                          # Network Time Protocol to set time via network.
    'p7zip'                        # 7z compression program
    'terminus-font'                # Font package with some bigger fonts for login terminal
    'unrar'                        # RAR compression program
    'unzip'                        # Zip compression program
    'wget'                         # Remote content retrieval
    'zip'                          # Zip compression program
    'zstd'                         # Zstandard - Fast real-time compression algorithm
    
    
    # DEVELOPMENT ---------------------------------------------------------

    'apparmor'                     # Mandatory Access Control (MAC) using Linux Security Module (LSM)
    'snapd'                        # Service and tools for management of snap packages
    'extra-cmake-modules'          # Extra modules and scripts for CMake
    'neovim'                       # Text editor
    'sequoia-sq'                   # To check PGP key
    'docker'                       # Pack, ship and run any application as a lightweight container
    'python-pip'                   # The PyPA recommended tool for installing Python packages
    'wget'                         # Network utility to retrieve files from the Web
    'dropbox'                      # A free service that lets you bring your photos, docs, and videos anywhere and share them easily
    'python-gpgme'                 # Python bindings for GPGme
    'downgrade'                    # Bash script for downgrading one or more packages to a version in your cache or the A.L.A
    'wine-staging'                 # A compatibility layer for running Windows programs - Staging branch
    'wine-gecko'                   # Wine's built-in replacement for Microsoft's Internet Explorer
    'wine-mono'                    # Wine's built-in replacement for Microsoft's .NET Framework
    'anki-bin'                     # Helps you remember facts (like words/phrases in a foreign language) efficiently
    'ttf-kanjistrokeorders'        # Kanji stroke order font
    
    # Faster whisper
    'cuda'                         # NVIDIA's GPU programming toolkit
    'cudnn'                        # NVIDIA CUDA Deep Neural Network library

    
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

    # Vietnamese input ----------------------------------------------
    'fcitx5-bamboo'                # Bamboo (Vietnamese Input Method) engine support for Fcitx
    'fcitx5-gtk'                   # Fcitx5 gtk im module and glib based dbus client library
    'fcitx5-qt'                    # Fcitx5 Qt Library
    'fcitx5-configtool'            # Configuration Tool for Fcitx5

    # Chinese input -------------------------------------------------
    'fcitx5-chinese-addons'        # Addons related to Chinese
    'adobe-source-han-sans-cn-fonts'
    'adobe-source-han-serif-cn-fonts'
    'noto-fonts-cjk wqy-microhei'
    'wqy-microhei-lite' 
    'wqy-bitmapfont'
    'wqy-zenhei'
    'ttf-arphic-ukai'
    'ttf-arphic-uming'

    # Extra fonts
    'ttf-meslo-nerd-font-powerlevel10k'
    'ttf-sourcecodepro-nerd'
    'ttf-jetbrains-mono-nerd'

    # VPN
    'protonvpn-cli-community'      # A Community Linux CLI for ProtonVPN

    # OTHERS --------------------------------------------------------

    'mpv'                          # MPV player
    'smplayer'                     # Frontend GUI for mpv player
    'video-downloader'             # Application for downloading video
    'deluge'                       # Full-featured BitTorrent application
    'deluge-gtk'                   # Deluge GUI
    'okular'                       # PDF viewer
    'libreoffice-fresh'            # Office
    'firefox'	               # Web browser
    'ferdium-bin'	               # Messenger, discord... manager
    'nomacs'                       # Image viewer
    'libheif'                      # An HEIF and AVIF file format decoder and encoder
    'konsave'                      # Import, export, extract KDE Plasma configuration profile
    'ttf-ms-fonts'                 # Core TTF Fonts from Microsoft
    'noto-fonts'                   # Google Noto TTF fonts
    'ttf-liberation'               # Font family which aims at metric compatibility with Arial, Times New Roman, and Courier New
    'otf-atkinson-hyperlegible'    # A typeface focusing on leterform distinction for legibility for low vision readers
    'nerd-fonts-inter'             # Inter Font, patched with the Nerd Fonts Patcher
    'powerline-fonts'              # Patched fonts for powerline
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    yay -Syu "$PKG" --noconfirm --needed
done

# Change default shell to zsh
sudo chsh -s /usr/bin/zsh

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install powerlevel10k theme for zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
sed -i 's/ZSH_THEME="font"/ZSH_THEME="powerlevel10k/powerlevel10k"/' .zshrc

# Enable QEMU connection for virt-manager
sudo systemctl enable libvirtd.service

# Enable Apparmor and Snap.Apparmor
sudo systemctl enable apparmor.service
sudo systemctl enable snapd.apparmor.service

# Enable Snapd socket
sudo systemctl enable snapd.socket

# Add user into kvm and libvirt groups
sudo usermod -aG kvm,libvirt $(whoami)
sudo systemctl restart libvirtd.service

# Enable virtual network and set it to autostart
sudo virsh net-start default
sudo virsh net-autostart default

# Enable trim for improving SSD performance
sudo systemctl enable fstrim.timer

# Oh-my-bash theme configuration
# cd ~
# cp ~/.bashrc ~/.bashrc.orig
# cp /usr/share/oh-my-bash/bashrc ~/.bashrc
# sed -i 's/OSH_THEME="font"/OSH_THEME="agnoster"/' .bashrc

# Force to use ffmpeg as qt6-multimedia backend
echo 'export QT_MEDIA_BACKEND=ffmpeg' >> ${HOME}/.zshrc

# Set up alias for updating (less effort, less typo)
echo "alias up='yay -Syu --noconfirm --needed; yay -Sc --noconfirm'" >> ~/.zshrc

# Enable docker service and add user to docker group
sudo usermod -aG docker $(whoami)
sudo systemctl enable docker.service

# Set up for Fcitx5
echo "export XMODIFIERS=@im=fcitx" >> ~/.zshrc
echo "export SDL_IM_MODULE=fcitx" >> ~/.zshrc
echo "export GLFW_IM_MODULE=ibus" >> ~/.zshrc

# Enable pipewire, pipewire-pulse and wireplumber globally
sudo systemctl --global enable pipewire.socket pipewire-pulse.socket
sudo systemctl --global enable pipewire.service pipewire-pulse.service wireplumber.service

echo "                    ========================="
echo "                    Configuring KDE Plasma..."
echo "                    ========================="

#Set atkinson hyperlegible to be system fonts
# kwriteconfig5 --file kdeglobals --group General --key fixed 'Atkinson Hyperlegible,10,-1,5,50,0,0,0,0,0'
# kwriteconfig5 --file kdeglobals --group General --key font 'Atkinson Hyperlegible,10,-1,5,50,0,0,0,0,0'
# kwriteconfig5 --file kdeglobals --group General --key menuFont 'Atkinson Hyperlegible,10,-1,5,50,0,0,0,0,0'
# kwriteconfig5 --file kdeglobals --group General --key smallestReadableFont 'Atkinson Hyperlegible,8,-1,5,50,0,0,0,0,0'
# kwriteconfig5 --file kdeglobals --group General --key toolBarFont 'Atkinson Hyperlegible,10,-1,5,50,0,0,0,0,0'

# Disable recent file tracking
#kwriteconfig5 --file kdeglobals --group RecentDocuments --key UseRecent false

# Use Google chrome browser for http and https URLs.
# kwriteconfig5 --file kdeglobals --group 'General' --key 'BrowserApplication' 'firefox.desktop'

# Use fastest animation speed.
# kwriteconfig5 --file kwinrc --group Compositing --key 'AnimationSpeed' '0'

# Turn off alert noise when AC adapter is unplugged.
# kwriteconfig5 --file powerdevil.notifyrc --group 'Event/unplugged' --key 'Action' ''

# Turn off alert noise when trash is emptied.
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/Trash: emptied' --key 'Action' ''

# Turn off alert noises for warnings and errors (popup instead).
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/catastrophe' --key 'Action' 'Popup'
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/fatalerror' --key 'Action' 'Popup'
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/messageCritical' --key 'Action' 'Popup'
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/messageInformation' --key 'Action' 'Popup'
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/messageWarning' --key 'Action' 'Popup'
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/messageboxQuestion' --key 'Action' 'Popup'
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/notification' --key 'Action' 'Popup'
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/printerror' --key 'Action' 'Popup'
# kwriteconfig5 --file  plasma_workspace.notifyrc --group 'Event/warning' --key 'Action' 'Popup'

# Turn off alerts for console bells.
# kwriteconfig5 --file  konsole.notifyrc --group 'Event/BellInvisible' --key 'Action' ''
# kwriteconfig5 --file  konsole.notifyrc --group 'Event/BellVisible' --key 'Action' ''

# Disable annoying automatically screen locking
# kwriteconfig5 --file  kscreenlockerrc --group 'Daemon' --key 'Autolock' 'false'

# Narrower window drop shadows.
# kwriteconfig5 --file breezerc --group Common --key 'ShadowSize' 'ShadowSmall'

# Turn off kwallet.
# kwriteconfig5 --file kwalletrc --group Wallet --key 'Enabled' 'false'
# kwriteconfig5 --file kwalletrc --group Wallet --key 'First Use' 'false'

# Disable file indexing by baloofile.
# kwriteconfig5 --file kcmshell5rc --group Basic Settings --key 'Indexing-Enabled' 'false'
# kwriteconfig5 --file baloofilerc --group Basic Settings --key 'Indexing-Enabled' 'false'

# Don't show media controls on the lock screen.
# kwriteconfig5 --file kscreenlockerrc --group Greeter --group 'LnF' --group 'General' --key 'showMediaControls' --type 'bool' 'false'

# Make sure desktop session starts empty
# kwriteconfig5 --file ksmserverrc --group General --key 'loginMode' 'default'

# Open new documents in tabs.
# kwriteconfig5 --file okularpartrc --group General --key 'ShellOpenFileInTabs' --type 'bool' 'true'

# Make yakuake full-width.
# kwriteconfig5 --file yakuakerc --group Window --key 'Width' '100'

# Make yakuake animation instant.
# kwriteconfig5 --file yakuakerc --group Animation --key 'Frames' '0'

# Allow empty clipboard.
# kwriteconfig5 --file klipperrc --group General --key 'PreventEmptyClipboard' --type bool 'false'

# Set language to "American English"
# kwriteconfig5 --file kdeglobals --group Translations --key 'LANGUAGE' 'en_US'

# Make kde faster, effects are for people who have leisure time.
# kwriteconfig5 --file kdeglobals --group "KDE-Global GUI Settings" --key "GraphicEffectsLevel" 0

# Power management
# kwriteconfig5 --file powermanagementprofilesrc --group AC --group SuspendSession  --key idleTime 1200000
# kwriteconfig5 --file powermanagementprofilesrc --group AC --group SuspendSession  --key suspendThenHibernate false
# kwriteconfig5 --file powermanagementprofilesrc --group AC --group SuspendSession  --key suspendType 1
# kwriteconfig5 --file powermanagementprofilesrc --group AC --group HandleButtonEvents --key lidAction 32
# kwriteconfig5 --file powermanagementprofilesrc --group AC --group HandleButtonEvents --key powerButtonAction 1
# kwriteconfig5 --file powermanagementprofilesrc --group AC --group HandleButtonEvents --key triggerLidActionWhenExternalMonitorPresent false
# kwriteconfig5 --file powermanagementprofilesrc --group Battery --group HandleButtonEvents --key lidAction 32
# kwriteconfig5 --file powermanagementprofilesrc --group Battery --group HandleButtonEvents --key powerButtonAction 1
# kwriteconfig5 --file powermanagementprofilesrc --group Battery --group HandleButtonEvents --key triggerLidActionWhenExternalMonitorPresent false
# kwriteconfig5 --file powermanagementprofilesrc --group LowBattery --group HandleButtonEvents --key lidAction 32
# kwriteconfig5 --file powermanagementprofilesrc --group LowBattery --group HandleButtonEvents --key powerButtonAction 1
# kwriteconfig5 --file powermanagementprofilesrc --group LowBattery --group HandleButtonEvents --key triggerLidActionWhenExternalMonitorPresent false

# Disable stupid touch screen edges and weird corners and thir animations
# kwriteconfig5 --file kwinrc --group Effect-Cube --key BorderActivate "9"
# kwriteconfig5 --file kwinrc --group Effect-Cube --key BorderActivateCylinder "9"
# kwriteconfig5 --file kwinrc --group Effect-Cube --key BorderActivateSphere "9"
# kwriteconfig5 --file kwinrc --group Effect-Cube --key TouchBorderActivate "9"
# kwriteconfig5 --file kwinrc --group Effect-Cube --key TouchBorderActivateCylinder "9"
# kwriteconfig5 --file kwinrc --group Effect-Cube --key TouchBorderActivateSphere "9"
# kwriteconfig5 --file kwinrc --group Effect-DesktopGrid --key BorderActivate "9"
# kwriteconfig5 --file kwinrc --group Effect-DesktopGrid --key TouchBorderActivate "9"
# kwriteconfig5 --file kwinrc --group Effect-PresentWindows --key BorderActivate "9"
# kwriteconfig5 --file kwinrc --group Effect-PresentWindows --key BorderActivateAll "9"
# kwriteconfig5 --file kwinrc --group Effect-PresentWindows --key BorderActivateClass "9"
# kwriteconfig5 --file kwinrc --group Effect-PresentWindows --key TouchBorderActivate "9"
# kwriteconfig5 --file kwinrc --group Effect-PresentWindows --key TouchBorderActivateAll "9"
# kwriteconfig5 --file kwinrc --group Effect-PresentWindows --key TouchBorderActivateClass "9"
# kwriteconfig5 --file kwinrc --group TabBox --key BorderActivate "9"
# kwriteconfig5 --file kwinrc --group TabBox --key BorderAlternativeActivate "9"
# kwriteconfig5 --file kwinrc --group TabBox --key TouchBorderActivate "9"
# kwriteconfig5 --file kwinrc --group TabBox --key TouchBorderAlternativeActivate "9"
# kwriteconfig5 --file kwinrc --group ElectricBorders --key Bottom "None"
# kwriteconfig5 --file kwinrc --group ElectricBorders --key BottomLeft "None"
# kwriteconfig5 --file kwinrc --group ElectricBorders --key BottomRight "None"
# kwriteconfig5 --file kwinrc --group ElectricBorders --key Left "None"
# kwriteconfig5 --file kwinrc --group ElectricBorders --key Right "None"
# kwriteconfig5 --file kwinrc --group ElectricBorders --key Top "None"
# kwriteconfig5 --file kwinrc --group ElectricBorders --key TopLeft "None"
# kwriteconfig5 --file kwinrc --group ElectricBorders --key TopRight "None"
# kwriteconfig5 --file kwinrc --group TouchEdges --key Bottom "None"
# kwriteconfig5 --file kwinrc --group TouchEdges --key Left "None"
# kwriteconfig5 --file kwinrc --group TouchEdges --key Right "None"
# kwriteconfig5 --file kwinrc --group TouchEdges --key Top "None"

# Set titlebar buttons
# kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key BorderSize "Normal"
# kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "MF"
# kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
# kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key CloseOnDoubleClickOnMenu "false"
# kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips "false"

# Set night color instant = 5500K
# kwriteconfig5 --file kwinrc --group NightColor --key Active "true"
# kwriteconfig5 --file kwinrc --group NightColor --key Mode "Constant"
# kwriteconfig5 --file kwinrc --group NightColor --key NightTemperature "5500"

# Set timezone
# kwriteconfig5 --file ktimezonedrc --group TimeZones --key LocalZone "Asia/Ho_Chi_Minh"

# Set single click = select
# kwriteconfig5 --file kdeglobals --group "KDE" --key "SingleClick" "false"

# Set Meta key to open/close Krunner
# kwriteconfig5 --file ~/.config/kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.kglobalaccel,/component/org_kde_krunner_desktop,,invokeShortcut,_launch" && qdbus org.kde.KWin /KWin reconfigure

# Show Alt+Tab popup as fast as possible
# kwriteconfig5 --file ~/.config/kwinrc --group TabBox --key DelayTime 0
# qdbus org.kde.KWin /KWin reconfigure

# Disable any kind of suspension
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Set dolphin to show hidden files
sed -i '/Hidden/d' ~/.local/share/dolphin/view_properties/global/.directory
echo "HiddenFilesShown=true" >> ~/.local/share/dolphin/view_properties/global/.directory

# Create translator for translating English audio files into text
# echo "#! /bin/bash" > ${HOME}/Downloads/translator.sh
# echo "whisper *.m* --model tiny.en --output_format txt --fp16 False --language en" >> ${HOME}/Downloads/translator.sh
# sudo chmod +x ${HOME}/Downloads/translator.sh

# Set up Virtual Environment for external python packages (for using PIP):
mkdir -p $HOME/.venvs  # create a folder for all virtual environments 
python3 -m venv $HOME/.venvs/MyEnv  # create MyEnv

# Install Faster whisper
# $HOME/.venvs/MyEnv/bin/python -m pip install faster-whisper

# Prepare python sript for translating:
# cat > $HOME/faster-whisper.py << EOF
#! $HOME/.venvs/MyEnv/bin/python
# from faster_whisper import WhisperModel
# import sys, glob, shutil, os

# model_size = "large-v3"
# Run on GPU with FP16
# model = WhisperModel(model_size, device="cuda", compute_type="float16")

# or run on GPU with INT8
 #model=WhisperModel(model_size,device="cuda",compute_type="int8_float16")
# or run on CPU with INT8
# model = WhisperModel(model_size, device="cpu", compute_type="int8")

# x = glob.glob(".m*")
# shutil.copyfile(x[0], 'audio.mp3')

# segments, info = model.transcribe("audio.mp3", beam_size=5)

# print("Detected language '%s' with probability %f" % (info.language, info.language_probability))

# origial_stdout = sys.stdout
# with open('output.txt', 'w') as f:
#     for segment in segments:
 #        print("[%.2fs -> %.2fs] %s" % (segment.start, segment.end, segment.text))
#    sys.stdout = original_stdout
# os.remove("audio.mp3")
# print("Done")
# EOF

# chmod +x $HOME/faster-whisper.py

echo
echo "Done!"
# rm ${HOME}/1\ -\ Post-install.sh
