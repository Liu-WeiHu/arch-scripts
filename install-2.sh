#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# set pacman
echo -e "\n\n"
echo -e "$CNT edit pacman.conf ..."
echo -e "\n\n"
sleep 1
sed -i 's/#Color/Color/' /etc/pacman.conf
cat >> /etc/pacman.conf << EOF
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF
sleep 1
pacman -Sy
pacman -S archlinuxcn-keyring

# if install keyring ERROR
echo -e "\n\n"
read -rep $'[\e[1;33mACTION\e[0m] - Is it successful to install ArchlinuxCn Key? (y,n) ' KEY
if [[ $KEY == "N" || $KEY == "n" ]]; then
    echo -e "$CNT - Setup starting install archlinuxcn ..."
    rm -rf /etc/pacman.d/gnupg
    pacman-key --init
    pacman-key --populate archlinux archlinuxcn
    sleep 1
fi

# install aur
echo -e "\n\n"
echo -e "$CNT install paru ..."
echo -e "\n\n"
sleep 1
pacman -S paru
sed -i 's/#BottomUp/BottomUp/' /etc/paru.conf
sleep 1

# add user
echo -e "\n\n"
echo -e "$CNT add user ..."
echo -e "\n\n"
sleep 1
read -rep $'[\e[1;33mACTION\e[0m] - Please enter the user name: ' USER
useradd -m -G wheel $USER
read -rep $'[\e[1;33mACTION\e[0m] - Please enter the user password: ' PASSWD
echo $PASSWD | passwd $USER --stdin
sed -i 's/^# %wheel ALL=/%wheel ALL=/g' /etc/sudoers
sleep 1

# add fonts
echo -e "\n\n"
pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-lxgw-wenkai-mono ttf-lxgw-wenkai
echo -e "\n\n"
sleep 1

# add zram
echo -e "\n\n"
read -rep $'[\e[1;33mACTION\e[0m] - Do you install zram? (y,n) ' ZRAM
if [[ $ZRAM == "Y" || $ZRAM == "y" ]]; then
    echo -e "$CNT - Setup starting install zram ..."
    cat > zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
EOF
    systemctl daemon-reload
    systemctl start /dev/nvme0n1p2
    sleep 1
fi

# add pipewire
echo -e "\n\n"
echo -e "$CNT install pipewire ..."
echo -e "\n\n"
sleep 1
pacman -S pipewire wireplumber pipewire-pulse
sleep 1

# add intel Installing a video card
echo -e "\n\n"
echo -e "$CNT starting Installing a video card ..."
echo -e "\n\n"
sleep 1
pacman -S mesa libva-utils intel-media-driver
sleep 1

# add fcitx5
echo -e "\n\n"
echo -e "$CNT install fcitx5 ..."
echo -e "\n\n"
sleep 1
fcitx5-im fcitx5-chinese-addons fcitx5-pinyin-zhwiki
cat >> /etc/environment << EOF
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF
sleep 1

# add mount
echo -e "\n\n"
read -rep $'[\e[1;33mACTION\e[0m] - Do you add mount /dev/sda1 > /dev/nvme0n1p2 ? (y,n) ' ZRAM
if [[ $ZRAM == "Y" || $ZRAM == "y" ]]; then
    echo -e "$CNT - Setup starting add mount ..."
    btrfs device add -f /dev/sda1 /
    sleep 1
fi

echo -e "$COK Has been completed.   === Check fstab, df, lsblk ==="

