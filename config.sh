#!/bin/bash

###==========================###
### CONFIGURAÇÕES DO USUÁRIO ###
###==========================###

# DISCO será definido dinamicamente no arch.in

HOSTNAME="archlinux"            # Nome do computador

TAMANHO_EFI="512M"
TAMANHO_RAIZ="40G"
TAMANHO_SWAP="8G"

PACOTES_ADICIONAIS=(
  vim
  htop
  btrfs-progs
  networkmanager
)

HOSTS_ENTRIES=$(cat <<EOF
127.0.0.1       localhost
::1             localhost
127.0.1.1       $HOSTNAME.localdomain    $HOSTNAME
EOF
)

###==========================###
### VARIÁVEIS DE INTERFACE   ###
###==========================###

_r='\e[31;1m'; _n='\e[36;1m'; _w='\e[37;1m'; _g='\e[32;1m'
_y='\e[33;1m'; _p='\e[35;1m'; _o='\e[m'

_s(){ printf ' %.0s' $(seq 1 $1); }
_bs(){ printf '\b%.0s' $(seq 1 $1); }

###==========================###
### MENSAGENS / COMANDOS     ###
###==========================###

declare -a _msg=(
  "Configurando o teclado...."
  "Testando a internet......."
  "Ativando NTP.............."
  "Criando as partições......"
  "Formatando EFI............"
  "Criando subvolumes BTRFS.."
  "Formatando SWAP..........."
  "Ativando SWAP............."
  "Montando EFI.............."
  "Instalando sistema base..."
  "Gerando fstab............."
)

declare -a _cmd=(
  "loadkeys br-abnt2"
  "ping -c1 archlinux.org"
  "timedatectl set-ntp true"
  "_criar_particoes_uefi"
  "mkfs.fat -F32 \${DISCO}1"
  "_configurar_btrfs_subvolumes"
  "mkswap \${DISCO}3"
  "swapon \${DISCO}3"
  "mount \${DISCO}1 /mnt/boot/efi"
  "pacstrap /mnt base linux linux-firmware btrfs-progs"
  "genfstab -U /mnt >> /mnt/etc/fstab"
)
