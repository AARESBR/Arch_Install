#!/bin/bash

###==========================###
###  INSTALADOR ARCH LINUX   ###
###  UEFI + BTRFS + CHROOT   ###
###==========================###

set -euo pipefail

# === VARIÁVEIS ===
HOSTNAME="archlinux"
TAMANHO_EFI="512M"
TAMANHO_RAIZ="10G"
TAMANHO_SWAP="2G"
PACOTES_ADICIONAIS=(btrfs-progs networkmanager grub efibootmgr htop vim micro git curl)

# === FUNÇÕES ===
erro() { echo -e "\e[31m[ERRO]\e[m $1"; exit 1; }
info() { echo -e "\e[36m[INFO]\e[m $1"; }
sucesso() { echo -e "\e[32m[OK]\e[m $1"; }

# === ESCOLHA DO DISCO ===
lsblk -d -o NAME,SIZE,MODEL | grep -v loop
read -rp "Disco para instalação (ex: /dev/sda): " DISCO
[[ -b "$DISCO" ]] || erro "Disco inválido"

# === PARTICIONAMENTO ===
info "Particionando $DISCO..."
(
  echo g
  echo n; echo; echo; echo +$TAMANHO_EFI; echo t; echo 1
  echo n; echo; echo; echo +$TAMANHO_RAIZ
  echo n; echo; echo; echo +$TAMANHO_SWAP; echo t; echo 3; echo 19
  echo w
) | fdisk "$DISCO"

# === FORMATAR ===
mkfs.fat -F32 ${DISCO}1
mkfs.btrfs -f ${DISCO}2
mkswap ${DISCO}3 && swapon ${DISCO}3

# === SUBVOLUMES BTRFS ===
mount ${DISCO}2 /mnt
for s in @ @home @var @opt @tmp; do btrfs subvolume create /mnt/$s; done
umount /mntt 

mount -o noatime,compress=zstd,subvol=@ ${DISCO}2 /mnt
mkdir -p /mnt/{boot/efi,home,var,opt,tmp}
mount -o noatime,compress=zstd,subvol=@home ${DISCO}2 /mnt/home
mount -o noatime,compress=zstd,subvol=@var  ${DISCO}2 /mnt/var
mount -o noatime,compress=zstd,subvol=@opt  ${DISCO}2 /mnt/opt
mount -o noatime,compress=zstd,subvol=@tmp  ${DISCO}2 /mnt/tmp
mount ${DISCO}1 /mnt/boot/efi

# === INSTALAR SISTEMA ===
pacstrap -K /mnt base linux linux-firmware ${PACOTES_ADICIONAIS[@]}
genfstab -U /mnt >> /mnt/etc/fstab

# === PÓS-INSTALAÇÃO ===
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime
hwclock --systohc

locale-gen
echo 'LANG=pt_BR.UTF-8' > /etc/locale.conf
echo 'pt_BR.UTF-8 UTF-8' >> /etc/locale.gen
echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf

echo "$HOSTNAME" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1       localhost
::1             localhost
127.0.1.1       $HOSTNAME.localdomain $HOSTNAME
EOT

systemctl enable NetworkManager

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

sucesso "Instalação concluída. Remova o pendrive e reinicie."
