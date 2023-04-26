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
echo -e "\n$CNT starting mkfs ..................\n"
sleep 1
mkfs.fat -F32 /dev/nvme0n1p1
sleep 1
mkfs.btrfs -f /dev/nvme0n1p2
sleep 1
mkfs.btrfs -f /dev/sda1
sleep 1
echo -e "\n$CAC mkfs done .................\n"

# mount
echo -e "\n$CNT starting create subvolume .................\n"
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
echo -e "\n$CAC created subvolume done .................\n"

echo -e "\n$CNT starting mount ......................\n"
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

echo -e "\n$CAC mount done .................\n"

lsblk

sleep 5


# disable reflector
echo -e "\n$CNT uninstall reflector .....................\n"
pacman -Rsnu reflector --noconfirm
echo -e "\n$CAC uninstall reflector done .................\n"
sleep 1

echo -e "\n$CNT fix mirrorlist ......................\n"
cat > /etc/pacman.d/mirrorlist << EOF
Server=https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server=https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
EOF

echo -e "\n$CAC created subvolume done .................\n"
sleep 1

# install system
echo -e "\n$CNT startings install system .......................\n"
sleep 1
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs neovim networkmanager git
echo -e "\n$CAC install system done .................\n"
sleep 1

# gen fstab
echo -e "\n$CNT generator fstab  ...................\n"
genfstab -U /mnt > /mnt/etc/fstab
echo -e "\n$CAC gen fstab done .................\n"
sleep 1

# chroot /mnt
echo -e "\n$COK Has been completed. Please >>>>>>>>>>>>>>>> arch-chroot /mnt \n"
