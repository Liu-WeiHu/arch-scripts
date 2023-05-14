#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# docker config
echo -e "\n$CNT starting config docker filesystem ................"
sudo systemctl enable --now docker
sleep 2
sudo mkdir /etc/docker
sleep 2
sudo sh -c 'cat << EOF > /etc/docker/daemon.json
{
  "storage-driver": "btrfs"
}
EOF'
sleep 2
sudo systemctl restart docker
sleep 2
echo -e "\n$CWR check docker filesystem is btrfs ..............."
docker info | grep Storage
sleep 5

# aur install
paru -S linuxqq visual-studio-code-bin dbeaver-ee
sleep 2

# setup wayland config
read -rep $'[\e[1;37mATTENTION\e[0m] - Are you setup wayland config? (y,n) ' WAYLANDC
if [[ $WAYLANDC == "Y" || $WAYLANDC == "y" ]]; then
    echo -e "$CNT - Setup starting config chrome wayland .................."
    echo "--gtk-version=4" >  ~/.config/chrome-flags.conf
    sleep 2
    echo -e "$CNT - Setup starting config code wayland .................."
    cat << EOF > ~/.config/code-flags.conf
--ozone-platform=wayland
--enable-wayland-ime
EOF
    sleep 2
    echo -e "$CNT - Setup starting config qq wayland .................."
    sudo sed -i '/Exec=linuxqq/c\Exec=linuxqq --ozone-platform=wayland --enable-wayland-ime %U' /usr/share/applications/qq.desktop
    sleep 2
    echo -e "\n$CWR 设置 -> 输入设备 -> 虚拟键盘 fcitx5 选中\n"
    sleep 2
    echo -e "$CNT - Setup starting config electron wayland .................."
    cat << EOF > ~/.config/electron-flags.conf
--enable-features=WaylandWindowDecorations
--ozone-platform-hint=auto
--enable-webrtc-pipewire-capturer
--gtk-version=4
EOF
    sleep 2
    echo -e "$CNT - Setup starting config java wayland .................."
    mkdir ~/.config/environment.d
    echo "_JAVA_AWT_WM_NONREPARENTING=1" > ~/.config/environment.d/env.conf
    sleep 2
    echo -e "\n$CNT - Setup starting config sddm wayland .................."
    sudo sh -c 'cat << EOF  > /etc/sddm.conf.d/10-wayland.conf
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen --inputmethod maliit-keyboard
EOF'
sleep 2
fi

# chrome gpu ++
echo -e "$CAC config chrome gpu ++ ......................................"
cat << EOF >> ~/.config/chrome-flags.conf
--ignore-gpu-blocklist
--enable-gpu-rasterization
--enable-zero-copy
--disable-gpu-driver-bug-workarounds
--enable-features=VaapiVideoDecoder,VaapiVideoEncoder
--enable-features=VaapiIgnoreDriverCheck
--disable-features=UseChromeOSDirectVideoDecoder
--enable-oop-rasterization
--enable-raw-draw
--use-vulkan
EOF
sleep 2

echo -e "\n$COK ============================================\n"





