#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# update
echo -e "\n\n"
echo -e "$CNT update pacman ..."
echo -e "\n\n"
pacman -Syy
sleep 1

# set time zone
echo -e "\n\n"
echo -e "$CNT Setting Zone Time ..."
echo -e "\n\n"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc --localtime
sleep 1

# add nvim -> vim and nvim -> vi
echo -e "\n\n"
read -rep $'[\e[1;33mACTION\e[0m] - Whether to add nvim -> vim and nvim -> vi soft links (y,n) ' NVIM
if [[ $NVIM == "Y" || $NVIM == "y" ]]; then
    echo -e "$CNT - Setup starting nvim -> vim,vi ..."
    ln -sf /usr/bin/nvim /usr/bin/vim
    ln -sf /usr/bin/nvim /usr/bin/vi
    sleep 1
fi

# set language
echo -e "\n\n"
echo -e "$CNT Setting Language ..."
echo -e "\n\n"
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
sleep 1
echo "LANG=en_US.UTF-8" > /etc/locale.conf
sleep 1

# set network
echo -e "\n\n"
echo -e "$CNT Setting Network ..."
echo -e "\n\n"
sleep 1
echo Arch > /etc/hostname
sleep 1
cat > /etc/hosts << EOF
127.0.0.1	      localhost
::1		          localhost
EOF
sleep 1

# set btrfs to initramfs
echo -e "\n\n"
read -rep $'[\e[1;33mACTION\e[0m] - Setting btrfs to mkinitcpio.conf, Are you using the btrfs file system? (y,n) ' CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
    echo -e "$CNT - Setup starting ..."
    sed -i '/^MODULES=/s/.$/ btrfs&/' /etc/mkinitcpio.conf
    sed -i '/^BINARIES=/s/.$/ btrfs&/' /etc/mkinitcpio.conf
    mkinitcpio -p
    sleep 1
fi

# set root password
echo -e "\n\n"
read -rep $'[\e[1;33mACTION\e[0m] - Setup passwd, Please enter password: ' PASSWD
echo $PASSWD | passwd root --stdin
sleep 1

# set fstrim
echo -e "\n\n"
read -rep $'[\e[1;33mACTION\e[0m] - Do you need to open fstrim serve? (y,n) ' FSTRIM
if [[ $FSTRIM == "Y" || $FSTRIM == "y" ]]; then
    systemctl enable fstrim.timer
    sleep 1
fi

# install ucode
echo -e "\n\n"
flag=0
while [ $flag -eq 0 ]; do
read -rep $'[\e[1;33mACTION\e[0m] - Please tell me your processor manufacturer, i=intel or a=amd (i,a)' CPU
if [[ $CPU == "I" || $CPU == "i" ]]; then
    pacman -S intel-ucode
    flag=1
elif [[ $CPU == "A" || $CPU == "a" ]]; then
    pacman -S amd-ucode
    flag=1
fi
done
sleep 1

# set grub
echo -e "\n\n"
pacman -S grub efibootmgr
sleep 1
sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"' /etc/default/grub
sed -i '/GRUB_PRELOAD_MODULES=/s/.$/ btrfs&/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg
sleep 1

# enable Network
echo -e "\n\n"
systemctl enable NetworkManager
sleep 1

echo -e "$COK Has been completed. Please exec >>  exit -> umount -R /mnt -> reboot"
