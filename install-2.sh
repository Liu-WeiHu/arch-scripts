#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# set pacman
echo -e "\n$CNT edit pacman.conf .................\n"
sleep 2
sed -i 's/#Color/Color/' /etc/pacman.conf
sleep 2
cat >> /etc/pacman.conf << EOF
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF
sleep 2
pacman -Sy
sleep 2
pacman -S archlinuxcn-keyring
echo -e "\n$CAC archlinuxcn done .................\n"
sleep 2

# if install keyring ERROR
read -rep $'[\e[1;37mATTENTION\e[0m] - Is it successful to install ArchlinuxCn Key? (y,n) ' KEY
if [[ $KEY == "N" || $KEY == "n" ]]; then
    echo -e "$CNT - Setup starting install archlinuxcn .................\n"
    rm -rf /etc/pacman.d/gnupg
    sleep 2
    pacman-key --init
    sleep 2
    pacman-key --populate archlinux archlinuxcn
    echo -e "\n$CAC archlinuxcn done .................\n"
    sleep 2
fi

# install aur
echo -e "\n$CNT install paru ................ln"
sleep 2
pacman -S paru
sleep 2
sed -i 's/#BottomUp/BottomUp/' /etc/paru.conf
echo -e "\n$CAC paru conf done .................\n"
sleep 2

# add user
echo -e "\n$CNT add user ..........................\n."
sleep 2
read -rep $'[\e[1;37mATTENTION\e[0m] - Please enter the user name: ' USER
useradd -m -G wheel $USER
read -rep $'[\e[1;37mATTENTION\e[0m] - Please enter the user password: ' PASSWD
echo -e "${PASSWD}\n${PASSWD}" | passwd $USER
sed -i 's/^# %wheel ALL=/%wheel ALL=/g' /etc/sudoers
echo -e "\n$CAC user done .................\n"
sleep 2

# add fonts
echo -e "\n$CNT install fonts ........................\n"
pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-lxgw-wenkai-mono ttf-lxgw-wenkai
echo -e "\n$CAC fonts done .................\n"
sleep 2

# add zram
read -rep $'[\e[1;37mATTENTION\e[0m] - Do you install zram? (y,n) ' ZRAM
if [[ $ZRAM == "Y" || $ZRAM == "y" ]]; then
    echo -e "$CNT - Setup starting install zram ................\n"
    pacman -S zram-generator
    sleep 2
    cat > zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
EOF
    sleep 2
    systemctl daemon-reload
    sleep 2
    systemctl start /dev/nvme0n1p2
    echo -e "\n$CAC zram done .................\n"
    sleep 2
fi

# add pipewire
echo -e "\n$CNT install pipewire .....................\n"
sleep 2
pacman -S pipewire wireplumber pipewire-pulse
echo -e "\n$CAC pipewire done .................\n"
sleep 2

# add intel Installing a video card
echo -e "\n$CNT starting Installing a video card ..................\n"
sleep 2
pacman -S mesa libva-utils intel-media-driver
echo -e "\n$CAC video card done .................\n"
sleep 2

# add fcitx5
echo -e "\n$CNT install fcitx5 .......................\n"
sleep 2
pacman -S fcitx5-im fcitx5-chinese-addons fcitx5-pinyin-zhwiki
sleep 2
cat >> /etc/environment << EOF
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF
echo -e "\n$CAC fcitx5 done .................\n"
sleep 2

# add mount
echo -e "\n\n"
read -rep $'[\e[1;37mATTENTION\e[0m] - Do you add mount /dev/sda1 > /dev/nvme0n1p2 ? (y,n) ' ADDM
if [[ $ADDM == "Y" || $ADDM == "y" ]]; then
    echo -e "$CNT - Setup starting add mount ..................\n"
    btrfs device add -f /dev/sda1 /
    echo -e "\n$CAC mount done .................\n"
    sleep 2
fi

sudo sed -i 's/subvolid=[0-9]\{3\}/nodiscard/g' /etc/fstab
sleep 2

echo -e "\n$COK Has been completed. >>>>>>>>>>>>>>>>>  Check fstab, df, lsblk \n"

