#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# install desktop
echo -e "\n$CNT install plasma-meta yakuake ...........................\n"
paru -S plasma-meta yakuake
sleep 2

# install wayland
read -rep $'[\e[1;37mATTENTION\e[0m] - Are you install wayland desktop? (y,n) ' WAYLAND
if [[ $WAYLAND == "Y" || $WAYLAND == "y" ]]; then
    echo -e "$CNT - Setup starting install wayland .................\n"
    paru -S sddm-git plasma-wayland-session  xdg-desktop-portal  xdg-desktop-portal-gtk xorg-xeyes wl-clipboard
    sleep 5
    echo -e "\n$CNT - Setup starting config sddm wayland .................\n"
    sudo sh -c 'cat << EOF  > /etc/sddm.conf.d/10-wayland.conf
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen --inputmethod maliit-keyboard
EOF'
sleep 2
echo -e "\n$CAC wayland done .................\n"
else
    echo -e "$CNT - Setup starting install x11 .................\n"
    paru -S sddm xclip xsel
    echo -e "\n$CAC x11 done .................\n"
fi
sleep 2
sudo systemctl enable sddm
sleep 2

# config
echo -e "\n$CNT starting config networkmanager .......................\n"
sudo sh -c 'cat << EOF  > /etc/NetworkManager/conf.d/20-connectivity.conf
[connectivity]
enabled=false
EOF'
echo -e "\n$CAC networkmanager done .................\n"
sleep 2

echo -e "\n$CNT starting config inputrc .......................\n"
cat > ~/.inputrc << EOF
set completion-ignore-case on
EOF
sleep 2
echo -e "\n$CNT starting config git .......................\n"
git config --global user.name "Liu WeiHu"
git config --global user.email 6460176@qq.com
sleep 2

echo -e "\n$CWR after 5s reboot ...................\n"
sleep 5

reboot