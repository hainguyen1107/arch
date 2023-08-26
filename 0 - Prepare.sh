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
curl -s "https://archlinux.org/mirrorlist/?country=KH&country=HK&country=ID&country=SG&country=TH&country=VN&protocol=http&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 -m 3 - > /etc/pacman.d/mirrorlist

echo -e "\nInstalling prereqs...\n"
pacman -S --noconfirm --needed gptfdisk

echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk: (example /dev/sda)"
read DISK
echo "--------------------------------------"
echo -e "\nFormatting disk...\n"
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

# Wipe all partitions
wipefs -a "${DISK}1"
wipefs -a "${DISK}2"
wipefs -a "${DISK}3"

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "ESP" "${DISK}1"
mkswap -L "SWAP" "${DISK}2"
swapon "${DISK}2"
mkfs.ext4 -L "ROOT" "${DISK}3"

# mount target
mount -t ext4 "${DISK}3" /mnt
mkdir -p /mnt/boot/efi
mount -t vfat "${DISK}1" /mnt/boot/

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
bootctl install --esp-path /mnt/boot

cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=${DISK}3 rw
EOF

cat <<EOF > /mnt/boot/loader/loader.conf
default arch
timeout 5
console-mode keep
editor no
EOF

#Set timezone
timedatectl --no-ask-password set-timezone Asia/Ho_Chi_Minh
timedatectl --no-ask-password set-ntp 1

# Set keymaps
localectl --no-ask-password set-keymap us

#Set language
printf "en_US.UTF-8 UTF-8\n" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
printf "LANG=en_US.UTF-8\n" > /mnt/etc/locale.conf

#Set hostname
echo "Please enter hostname:"
read hostname
hostnamectl --no-ask-password set-hostname $hostname
printf "127.0.0.1\tlocalhost\n" >> /mnt/etc/hosts
printf "::1\tlocalhost\n" >> /mnt/etc/hosts
printf "127.0.0.1\t$hostname.localdomain\t$hostname\n" >> /mnt/etc/hosts
arch-chroot /mnt systemctl enable NetworkManager

# Set new user
echo -e "\nEnter username to be created:\n"
read user
echo -e "\nEnter nickname to be created:\n"
read nickname
echo -e "\nEnter new password for $user:\n"
read uspw
arch-chroot /mnt useradd -mU -s /bin/bash -G lp,optical,wheel,uucp,disk,power,video,audio,storage,games,input $user -d /home/$user -c "$nickname"
echo "$user:$uspw" | chpasswd --root /mnt

# Set password for root
echo -e "\nEnter new password for root:\n"
read rtpw
echo "root:$rtpw" | chpasswd --root /mnt

# Add sudo right for user and remove password timeout
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
echo "Defaults timestamp_timeout=-1" >> /mnt/etc/sudoers

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/#//' /mnt/etc/pacman.conf


echo "--------------------------------------"
echo "--   SYSTEM READY FOR FIRST BOOT    --"
echo "--------------------------------------"
