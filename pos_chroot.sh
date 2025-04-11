#!/bin/bash

source /root/config.sh

ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime
hwclock --systohc

echo 'pt_BR.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG=pt_BR.UTF-8' > /etc/locale.conf
echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf

echo "$HOSTNAME" > /etc/hostname
echo "$HOSTS_ENTRIES" > /etc/hosts

pacman -Sy grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
