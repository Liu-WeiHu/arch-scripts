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
sleep 1

# install wayland
read -rep $'[\e[1;33mACTION\e[0m] - Are you install wayland desktop? (y,n) ' KEY
if [[ $KEY == "Y" || $KEY == "y" ]]; then
    echo -e "$CNT - Setup starting install wayland .................\n"
    paru -S sddm-git plasma-wayland-session  xdg-desktop-portal  xdg-desktop-portal-gtk
    echo -e "\n$CAC wayland done .................\n"
    sleep 1
    sudo sh -c 'cat << EOF  > /etc/sddm.conf.d/10-wayland.conf
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen --inputmethod maliit-keyboard
EOF'
else
    echo -e "$CNT - Setup starting install x11 .................\n"
    paru -S sddm
    echo -e "\n$CAC x11 done .................\n"
fi
sleep 1
sudo systemctl enable sddm
sleep 1

# config
echo -e "\n$CNT starting config .......................\n"
sudo sh -c 'cat << EOF  > /etc/NetworkManager/conf.d/20-connectivity.conf
[connectivity]
enabled=false
EOF'
sleep 1
cat > ~/.inputrc << EOF
set completion-ignore-case on
set show-all-if-ambiguous on
EOF
sleep 1

echo -e "\n$CWR after 5s reboot ...................\n"
sleep 5

reboot





