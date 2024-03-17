#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# cfdisk -> /efi 100M,

# setting timedate
echo -e "\n$CNT starting settings timedate ....................."
timedatectl set-ntp true
sleep 2
timedatectl set-timezone Asia/Shanghai
echo -e "\n$CAC timedate done ...................."
sleep 2


# mkfs
echo -e "\n$CNT starting mkfs ....................."
sleep 2
mkfs.fat -F32 /dev/nvme0n1p1
echo -e "\n$CAC nvme0n1p1 done ...................."
sleep 2
# 如果是多磁盘还需要加上 -d raid0 -m raid1
mkfs.btrfs -f -L "MyArch" --checksum xxhash /dev/nvme0n1p2
echo -e "\n$CAC nvme0n1p2 done ...................."
sleep 2
# mkfs.btrfs -f /dev/nvme0n1p1
# echo -e "\n$CAC nvme0n1p1 done ...................."
# sleep 2

# mount
echo -e "\n$CNT starting create subvolume ...................."
sleep 2
mount /dev/nvme0n1p2 /mnt

sleep 2
btrfs sub create /mnt/@
sleep 2
btrfs sub create /mnt/@home
sleep 2
btrfs sub create /mnt/@cache
sleep 2
btrfs sub create /mnt/@log
sleep 2
# btrfs sub create /mnt/@docker
# sleep 2
# btrfs sub create /mnt/@libvirt
# sleep 2
# btrfs sub create /mnt/@portables
# sleep 2
# btrfs sub create /mnt/@machines
# sleep 2

sleep 2
umount /mnt
echo -e "\n$CAC created subvolume done ...................."

echo -e "\n$CNT starting mount ........................."
sleep 2
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@  /dev/nvme0n1p2  /mnt
echo -e "\n$CAC root mounted done ...................."

sleep 2
mount /dev/nvme0n1p1 /mnt/efi --mkdir
echo -e "\n$CAC efi mounted done ...................."
sleep 2
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@home  /dev/nvme0n1p2  /mnt/home --mkdir
echo -e "\n$CAC home mounted done ...................."
sleep 2
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@cache  /dev/nvme0n1p2  /mnt/var/cache --mkdir
echo -e "\n$CAC cache mounted done ...................."
sleep 2
mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@log  /dev/nvme0n1p2  /mnt/var/log --mkdir
echo -e "\n$CAC log mounted done ...................."
# sleep 2
# mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@docker  /dev/nvme0n1p2  /mnt/var/lib/docker --mkdir
# echo -e "\n$CAC docker mounted done ...................."
# sleep 2
# mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@libvirt  /dev/nvme0n1p2  /mnt/var/lib/libvirt --mkdir
# echo -e "\n$CAC libvirt mounted done ...................."
# sleep 2
# mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@portables  /dev/nvme0n1p2  /mnt/var/lib/portables --mkdir
# echo -e "\n$CAC portables mounted done ...................."
# sleep 2
# mount -o noatime,ssd,compress=zstd,nodiscard,subvol=@machines  /dev/nvme0n1p2  /mnt/var/lib/machines --mkdir
echo -e "\n$CAC machines mounted done ...................."
sleep 2

lsblk

sleep 5


# disable reflector
echo -e "\n$CNT uninstall reflector ........................"
pacman -Rsnu reflector --noconfirm
echo -e "\n$CAC uninstall reflector done ...................."
sleep 2

echo -e "\n$CNT fix mirrorlist ........................."
cat > /etc/pacman.d/mirrorlist << EOF
Server=https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server=https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
EOF

echo -e "\n$CAC created subvolume done ...................."
sleep 2

# install system
echo -e "\n$CNT startings install system .........................."
sleep 2
pacstrap /mnt base base-devel linux linux-firmware linux-headers btrfs-progs neovim networkmanager git pacman-contrib
echo -e "\n$CAC install system done ...................."
sleep 2

# gen fstab
echo -e "\n$CNT generator fstab  ......................"
genfstab -U /mnt > /mnt/etc/fstab
echo -e "\n$CAC gen fstab done ...................."
sleep 2

# mv script
mv arch-scripts /mnt/root/

# chroot /mnt
echo -e "\n$COK Has been completed. Please >>>>>>>>>>>>>>>> arch-chroot /mnt \n"
