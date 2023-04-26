#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# cfdisk -> /boot 512M,

# mkfs
echo -e "\n\n"
echo -e "$CNT starting mkfs ..."
echo -e "\n\n"
sleep 1
mkfs.fat -F32 /dev/nvme0n1p1
sleep 1
mkfs.btrfs -f /dev/nvme0n1p2
sleep 1
mkfs.btrfs -f /dev/sda1
sleep 1

# mount
echo -e "\n\n"
echo -e "$CNT starting mount ..."
echo -e "\n\n"
sleep 1
mount /dev/nvme0n1p2 /mnt
sleep 1
cd /mnt
sleep 1
btrfs sub create @root
sleep 1
btrfs sub create @home
sleep 1
btrfs sub create @cache
sleep 1
btrfs sub create @log
sleep 1
btrfs sub create @docker
sleep 1
btrfs sub create @libvirt
sleep 1
cd ~
sleep 1
umount /mnt
echo -e "\n\n"
echo -e "$CNT btrfs created ..."
echo -e "\n\n"
sleep 1
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@root  /dev/nvme0n1p2  /mnt
sleep 1
mkdir /mnt/{boot,home,var}
sleep 1
mkdir /mnt/var/{cache,log,lib}
sleep 1
mkdir /mnt/var/lib/{docker,libvirt}
sleep 1
mount /dev/nvme0n1p1 /mnt/boot
sleep 1
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@home  /dev/nvme0n1p2  /mnt/home
sleep 1
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@cache  /dev/nvme0n1p2  /mnt/var/cache
sleep 1
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@log  /dev/nvme0n1p2  /mnt/var/log
sleep 1
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@docker  /dev/nvme0n1p2  /mnt/var/lib/docker
sleep 1
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@libvirt  /dev/nvme0n1p2  /mnt/var/lib/libvirt
sleep 1

echo -e "\n\n"
echo -e "$COK mount success......."
echo -e "\n\n"

lsblk

sleep 5


# disable reflector
echo -e "\n\n"
pacman -Rsnu reflector
sleep 1

cat > /etc/pacman.d/mirrorlist << EOF
Server=https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server=https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
EOF

sleep 1

# install system
echo -e "\n\n"
echo -e "$CNT startings install system ..."
echo -e "\n\n"
sleep 1
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs neovim networkmanager
sleep 1

# gen fstab
echo -e "\n\n"
echo -e "$CNT generator fstab  ..."
echo -e "\n\n"
genfstab -U /mnt > /mnt/etc/fstab
sleep 1

# chroot /mnt
echo -e "\n\n"
echo -e "$COK Has been completed. Please >>>>>>>>>>>>>>>> arch-chroot /mnt"
