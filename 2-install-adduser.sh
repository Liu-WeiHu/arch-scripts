#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# check network
ping -c 3 www.baidu.com > /dev/null
if [ $? -eq 0 ]; then
echo -e "\n$COK network connected..................."
else
echo -e "\n$CER network not connected, You must connect network ......."
exit 1
fi
sleep 1


# set pacman
echo -e "\n$CNT edit pacman.conf ..................."
sleep 2
sed -i 's/#Color/Color/' /etc/pacman.conf
sleep 1
sed -i '/Color/a\\ILoveCandy' /etc/pacman.conf
sleep 1
sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sleep 2
cat >> /etc/pacman.conf << EOF
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF
sleep 2
pacman -Sy
sleep 2
pacman-key --lsign-key "farseerfc@archlinux.org"
sleep 2
pacman -S archlinuxcn-keyring
echo -e "\n$CAC archlinuxcn done ..................."
sleep 2

# if install keyring ERROR
read -rep $'[\e[1;37mATTENTION\e[0m] - Is it successful to install ArchlinuxCn Key? (y,n) ' KEY
if [[ $KEY == "N" || $KEY == "n" ]]; then
echo -e "$CNT - Setup starting install archlinuxcn ..................."
rm -rf /etc/pacman.d/gnupg
sleep 2
pacman-key --init
sleep 2
pacman-key --populate archlinux archlinuxcn
echo -e "\n$CAC archlinuxcn done ..................."
sleep 2
fi

# install aur
echo -e "\n$CNT install paru ................ln"
sleep 2
pacman -S paru
sleep 2
sed -i 's/#BottomUp/BottomUp/' /etc/paru.conf
echo -e "\n$CAC paru conf done ..................."
sleep 2

# add user
echo -e "\n$CNT add user ............................."
sleep 2
read -rep $'[\e[1;37mATTENTION\e[0m] - Please enter the user name: ' UUSER
useradd -m -G wheel $UUSER
read -rep $'[\e[1;37mATTENTION\e[0m] - Please enter the user password: ' PASSWD
echo -e "${PASSWD}\n${PASSWD}" | passwd $UUSER
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
echo -e "\n$CAC user done ..................."
sleep 2

# add fonts
echo -e "\n$CNT install fonts .........................."
pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd  ttf-lxgw-wenkai-mono ttf-lxgw-wenkai
echo -e "\n$CAC fonts done ..................."
sleep 2

# add zram
read -rep $'[\e[1;37mATTENTION\e[0m] - Do you install zram? (y,n) ' ZRAM
if [[ $ZRAM == "Y" || $ZRAM == "y" ]]; then
echo -e "$CNT - Setup starting install zram .................."
pacman -S zram-generator
sleep 2
cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
sleep 2
systemctl daemon-reload
sleep 2
systemctl start /dev/nvme0n1p2
# disable zswap, because kernel default enable zswap.
sleep 2
sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/s/.$/ zswap.enabled=0&/' /etc/default/grub
sleep 2

read -rep $'[\e[1;37mATTENTION\e[0m] - Do you want to probe other systems? (y,n) ' PROBE
if [[ $PROBE == "Y" || $PROBE == "y" ]]; then
echo -e "$CNT - setting probe ...................."
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
sleep 1
pacman -S os-prober
echo -e "\n$CAC probe done ..................."
fi
sleep 2
grub-mkconfig -o /efi/grub/grub.cfg
sleep 2

# Optimizing swap on zram
cat > /etc/sysctl.d/99-vm-zram-parameters.conf <<EOF
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF
echo -e "\n$CAC zram done ..................."
sleep 2
fi

# add pipewire
echo -e "\n$CNT install pipewire ......................."
sleep 2
pacman -S pipewire wireplumber pipewire-pulse gst-plugin-pipewire pipewire-alsa pipewire-audio pipewire-jack --needed
echo -e "\n$CAC pipewire done ..................."
sleep 2

# add Integrated graphics
echo -e "\n$CNT starting install Integrated graphics Please select your cpu type ......................"
pacman -S mesa libva-utils vulkan-icd-loader vulkan-tools
sleep 2
select graphics in "cpu-intel" "cpu-amd"
do
	case $graphics in
		"cpu-intel")
			pacman -S intel-media-driver vulkan-intel  
			break
			;;
		"cpu-amd")
			pacman -S libva-mesa-driver vulkan-radeon 
			break
			;;
		*)
			echo "Input error, please retype"
	esac
done
echo -e "\n$CAC Integrated graphics done ..................."
sleep 2

# add fcitx5
echo -e "\n$CNT install fcitx5 ........................."
sleep 2
pacman -S fcitx5-im fcitx5-chinese-addons fcitx5-pinyin-zhwiki fcitx5-pinyin-moegirl
sleep 2
cat >> /etc/environment << EOF
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF
echo -e "\n$CAC fcitx5 done ..................."
sleep 2


sed -i 's/subvolid=[0-9]\{3\}/nodiscard/g' /etc/fstab
sleep 2

# mv script to home
mv ~/arch-scripts /home/$UUSER/

echo -e "\n$COK Has been completed. >>>>>>>>>>>>>>>>>  Check fstab, df, lsblk \n"

