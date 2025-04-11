#!/bin/bash

source config.sh
: "${DISCO:?Variável DISCO não definida. Execute via arch.in}"

_criar_particoes_uefi(){
  (
    echo g
    echo n; echo; echo; echo +$TAMANHO_EFI; echo t; echo 1
    echo n; echo; echo; echo +$TAMANHO_RAIZ
    echo n; echo; echo; echo +$TAMANHO_SWAP; echo t; echo 3; echo 19
    echo w
  ) | fdisk "$DISCO"
}

_configurar_btrfs_subvolumes(){
  mkfs.btrfs -f ${DISCO}2
  mount ${DISCO}2 /mnt

  for sub in @ @var @tmp @opt @home; do
    btrfs subvolume create /mnt/$sub
  done

  umount /mnt

  mount -o noatime,compress=zstd,subvol=@ ${DISCO}2 /mnt
  mkdir -p /mnt/{boot/efi,var,tmp,opt,home}

  mount -o noatime,compress=zstd,subvol=@var ${DISCO}2 /mnt/var
  mount -o noatime,compress=zstd,subvol=@tmp ${DISCO}2 /mnt/tmp
  mount -o noatime,compress=zstd,subvol=@opt ${DISCO}2 /mnt/opt
  mount -o noatime,compress=zstd,subvol=@home ${DISCO}2 /mnt/home
}

_instalar_pacotes_adicionais(){
  echo -e "\n$_y➜$_o Instalando pacotes adicionais..."
  arch-chroot /mnt pacman -Sy --noconfirm "${PACOTES_ADICIONAIS[@]}"
  [[ $? -eq 0 ]] && echo -e "$_g✔$_o Pacotes instalados." || echo -e "$_r✖$_o Falha nos pacotes."
}

_throbber_do(){
  setterm -cursor off
  z=1
  while [[ "$z" -lt 100 ]]; do echo -ne "\b█"; sleep 0.02; ((z++)); [[ "$z" -gt 98 ]] && z=1; done
}

_run(){ { while true; do _throbber_do; done; } & pid=$!; }
