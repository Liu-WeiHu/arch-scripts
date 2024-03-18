#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# install desktop
echo -e "\n$CNT install plasma-meta yakuake ............................."
paru -S plasma-meta konsole
sleep 2

# install wayland
read -rep $'[\e[1;37mATTENTION\e[0m] - Are you install wayland desktop? (y,n) ' WAYLAND
if [[ $WAYLAND == "Y" || $WAYLAND == "y" ]]; then
echo -e "$CNT - Setup starting install wayland ..................."
paru -S sddm xdg-desktop-portal xdg-desktop-portal-kde xorg-xeyes wl-clipboard spectacle plasma-wayland-protocols --needed
sleep 2
echo -e "\n$CAC wayland done ..................."
else
echo -e "$CNT - Setup starting install x11 ..................."
paru -S sddm xclip xsel flameshot --needed
echo -e "\n$CAC x11 done ..................."
fi
sleep 2
sudo systemctl enable sddm
sleep 2

# config
echo -e "\n$CNT starting config networkmanager ........................."
sudo sh -c 'cat << EOF  > /etc/NetworkManager/conf.d/20-connectivity.conf
[connectivity]
enabled=false
EOF'
echo -e "\n$CAC networkmanager done ..................."
sleep 2

echo -e "\n$CNT starting config inputrc ........................."
cat > ~/.inputrc << EOF
set completion-ignore-case on
EOF
sleep 2
echo -e "\n$CNT starting config git ........................."
git config --global user.name "Liu WeiHu"
git config --global user.email 6460176@qq.com
sleep 2

# close kde baloo
echo -e "\n$CNT starting Disabling the baloo ........................."
balooctl6 suspend
sleep 1
balooctl6 disable
sleep 1
balooctl6 purge
sleep 2

echo -e "\n$COK Has been completed. >>>>>>>>>>>>>>>>>  reboot \n"
