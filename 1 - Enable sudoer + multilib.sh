#!/bin/bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Add sudo right for user
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo
echo "Done!"
echo

exit
