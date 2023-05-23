#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# update
echo -e "\n$CNT update pacman .............."
pacman -Syy
sleep 2

# set time zone
echo -e "\n$CNT Setting Zone Time ................."
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
echo -e "\n$CAC zone time done ..................."
sleep 2

# add nvim -> vim and nvim -> vi
read -rep $'[\e[1;37mATTENTION\e[0m] - Whether to add nvim -> vim and nvim -> vi soft links (y,n) ' NVIM
if [[ $NVIM == "Y" || $NVIM == "y" ]]; then
    echo -e "$CNT - Setup starting nvim -> vim,vi ..............."
    ln -sf /usr/bin/nvim /usr/bin/vim
    ln -sf /usr/bin/nvim /usr/bin/vi
    echo -e "\n$CAC nvim done ..................."
    sleep 2
fi

# set language
echo -e "\n$CNT Setting Language .................."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
sleep 2
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo -e "\n$CAC language done ..................."
sleep 2

# set network
echo -e "\n$CNT Setting Network ..............."
sleep 2
echo Arch > /etc/hostname
sleep 2
cat > /etc/hosts << EOF
127.0.0.1	      localhost
::1		          localhost
EOF
echo -e "\n$CAC network done ..................."
sleep 2

# set btrfs to initramfs
read -rep $'[\e[1;37mATTENTION\e[0m] - Setting btrfs to mkinitcpio.conf, Are you using the btrfs file system? (y,n) ' CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
    echo -e "$CNT - Setup starting mkinitcpio ..............."
    sed -i '/^MODULES=/s/.$/ btrfs&/' /etc/mkinitcpio.conf
    sed -i '/^BINARIES=/s/.$/ btrfs&/' /etc/mkinitcpio.conf
    echo -e "\n$CAC mkinitcpio done ..................."
    sleep 2
fi

# set root password
read -rep $'[\e[1;37mATTENTION\e[0m] - Setup root passwd, Please enter root password: ' PASSWD
echo -e "${PASSWD}\n${PASSWD}" | passwd root
echo -e "\n$CAC passwd done ..................."
sleep 2

# set fstrim
read -rep $'[\e[1;37mATTENTION\e[0m] - Do you need to open fstrim serve? (y,n) ' FSTRIM
if [[ $FSTRIM == "Y" || $FSTRIM == "y" ]]; then
    systemctl enable fstrim.timer
    echo -e "\n$CAC fstrim done ..................."
    sleep 2
fi

# install ucode
echo -e "\n$CNT starting install ucode ......................"
select name in "cpu-intel" "cpu-amd"
do
	case $name in
		"cpu-intel")
			pacman -S intel-ucode
			break
			;;
		"cpu-amd")
			pacman -S amd-ucode
			break
			;;
		*)
			echo "Input error, please retype"
	esac
done
echo -e "\n$CAC ucode done ..................."
sleep 2

# set grub
echo -e "\n$CNT startings install grub ..............."
pacman -S grub efibootmgr
sleep 2
sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"' /etc/default/grub
sed -i '/GRUB_PRELOAD_MODULES=/s/.$/ btrfs&/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch
sleep 2
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "\n$CAC grub done ..................."
sleep 2

# enable Network
echo -e "\n$CNT starting auto network ....................."
systemctl enable NetworkManager
sleep 2

echo -e "\n$COK Has been completed. Please exec >>>>>>>>>>>>>>>>>>>>>>>>>  exit, umount -R /mnt, reboot \n"
