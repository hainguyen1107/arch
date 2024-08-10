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
    'python-gpgme'                 # Python bindings for GPGme
    'downgrade'                    # Bash script for downgrading one or more packages to a version in your cache or the A.L.A
    'wine-staging'                 # A compatibility layer for running Windows programs - Staging branch
    'wine-gecko'                   # Wine's built-in replacement for Microsoft's Internet Explorer
    'wine-mono'                    # Wine's built-in replacement for Microsoft's .NET Framework
    'anki-bin'                     # Helps you remember facts (like words/phrases in a foreign language) efficiently
    'ttf-kanjistrokeorders'        # Kanji stroke order font

    # Cloud storage
    'megasync-bin'                 # Easy automated syncing between your computers and your MEGA cloud drive
    'maestral'                     # A light-weight and open-source Dropbox client
    
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
    'grimshot'                     # A helper for screenshots within sway
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    yay -Syu "$PKG" --noconfirm --needed
done

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install powerlevel10k theme for zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
sed -i 's/ZSH_THEME="font"/ZSH_THEME="powerlevel10k/powerlevel10k"/' .zshrc

# Install plugins and spaceship for zsh
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete

sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete)/g' $HOME/.zshrc
sed -i 's/ZSH_THEME=".*"/ZSH_THEME="power10k\/powerlevel10k"/g' $HOME/.zshrc 

# Disable autocorrection of zsh
echo "#Disable auto correct\nunsetopt correct_all" >> $HOME/.zshrc

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

# Disable any kind of suspension
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Set dolphin to show hidden files
sed -i '/Hidden/d' ~/.local/share/dolphin/view_properties/global/.directory
echo "HiddenFilesShown=true" >> ~/.local/share/dolphin/view_properties/global/.directory

# Fix Dolphin bug of not showing default apps
sudo echo "XDG_MENU_PREFIX=arch-" >> /etc/environment
sudo kbuildsycoca6

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

# Add SSH private key to the ssh-agent
mkdir -p $HOME/.ssh
ssh-add $HOME/.ssh/id_ed25519

# Git configuration
git config --global user.name "hainguyen1107"
git config --global user.email "tamtunhubui@gmail.com"


# Remove archived journal files until the disk space they use falls below 100M
sudo journalctl --vacuum-size=100M

# Change default shell to zsh
sudo chsh -s /usr/bin/zsh
source $HOME/.zshrc

echo
echo "Done!"
# rm ${HOME}/1\ -\ Post-install.sh
