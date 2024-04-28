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
paru -S plasma-meta konsole sddm xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-kde xorg-xeyes  \
        wl-clipboard spectacle plasma-wayland-protocols gwenview dolphin \
        ark 7-zip-full unrar unarchiver kate google-chrome \
        libreoffice-still libreoffice-still-zh-cn \
        linuxqq visual-studio-code-bin wechat-universal-bwrap 
sleep 1

# setup sddm
echo -e "\n$CNT starting setup sddm ........................"
sudo systemctl enable sddm
sleep 1

# setup blue
echo -e "\n$CNT starting setup blue ........................"
sudo systemctl enable --now bluetooth
sleep 1

# close kde baloo
echo -e "\n$CNT starting Disabling the baloo ........................."
balooctl6 suspend
sleep 1
balooctl6 disable
sleep 1
balooctl6 purge
sleep 1

# disable startup discover
mkdir ~/.config/autostart
cp /etc/xdg/autostart/org.kde.discover.notifier.desktop  ~/.config/autostart/
cp /etc/xdg/autostart/kaccess.desktop  ~/.config/autostart/
sleep 1
echo Hidden=True >> ~/.config/autostart/org.kde.discover.notifier.desktop
echo Hidden=True >> ~/.config/autostart/kaccess.desktop
sleep 1
echo -e "\n$CAC disable startup discover done ..................."

# set fcitx env
mkdir ~/.config/environment.d
sleep 1
cat << EOF > ~/.config/environment.d/env.conf
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF
sleep 1
echo -e "\n$CAC set fcitx env done ..................."

# # kvm qemu install
# read -rep $'[\e[1;37mATTENTION\e[0m] - Are you install virt-manager qemu ? (y,n) ' QEMU
# if [[ $QEMU == "Y" || $QEMU == "y" ]]; then
# echo -e "$CNT - Setup starting install virt-manager qemu-full dnsmasq iptables-nft samba ..................."
# paru -S virt-manager qemu-desktop dnsmasq iptables-nft samba
# sleep 1

# # smb config
# echo -e "\n$CNT starting config smb ........................"
# sudo sh -c 'cat << EOF  > /etc/samba/smb.conf
# [Shared]
# comment = Shared Folder for QEMU
# path = /home/liu/Shared
# public = yes
# valid users = liu
# browseable = yes
# writeable = yes
# read only = no
# security = user
# passdb backend = tdbsam
# force user = liu
# [global]
# server min protocol = NT1
# lanman auth = yes
# ntlm auth = yes
# EOF'
# sleep 1
# sudo systemctl enable --now smb
# sleep 1
# read -rep $'[\e[1;37mATTENTION\e[0m] - Enter the smb password: ' SMBP
# echo -e "${SMBP}\n${SMBP}" | sudo smbpasswd -a $USER
# sleep 1

# # libvirt config
# sleep 1
# echo -e "\n$CNT starting config libvirt ........................"
# sudo usermod -a -G libvirt $USER
# sudo sh -c 'cat << EOF  > /etc/polkit-1/rules.d/50-libvirt.rules
# polkit.addRule(function(action, subject) {
# if (action.id == "org.libvirt.unix.manage" &&
# subject.isInGroup("libvirt")) {
# return polkit.Result.YES;
# }
# });
# EOF'
# sleep 1
# sudo systemctl enable --now libvirtd.service
# sleep 1
# sudo virsh net-autostart default

# # configure qemu
# sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/s/.$/ qxl bochs_drm&/' /etc/default/grub
# sudo grub-mkconfig -o /efi/grub/grub.cfg

# # end
# sleep 1
# echo -e "\n$CAC virt-manager qemu done ..................."
# fi

# # setup xrandr
# read -rep $'[\e[1;37mATTENTION\e[0m] - Are you install xrandr and configure it? (y,n) ' XRANDR
# if [[ $XRANDR == "Y" || $XRANDR == "y" ]]; then
# echo -e "$CNT - Setup starting install xrandr and configure ..................."
# paru -S xorg-xrandr
# sleep 1
# sudo sh -c 'cat << EOF >> /usr/share/sddm/scripts/Xsetup
# intern=eDP-1
# extern1=DP-1-1
# extern2=DP-1-2
# xrandr=\$(xrandr)
# output=
# if [[ "\$xrandr" =~ "\$extern1 connected" ]]; then
# output=\$extern1
# elif [[ "\$xrandr" =~ "\$extern2 connected" ]]; then
# output=\$extern2
# fi

# if [[ -n "\$output" ]]; then
# xrandr --output "\$intern" --off --output "\$output" --auto
# else
# xrandr --output "\$intern" --auto
# fi
# EOF'
# sleep 1
# echo -e "\n$CAC xrandr done ..................."
# fi
# sleep 1

# # install wireshark
# read -rep $'[\e[1;37mATTENTION\e[0m] - Are you install wireshark and configure it? (y,n) ' WIRESHARK
# if [[ $WIRESHARK == "Y" || $WIRESHARK == "y" ]]; then
# paru -S wireshark-qt
# sleep 1
# sudo gpasswd -a $USER wireshark
# sleep 1
# fi

echo -e "\n$COK Has been completed. >>>>>>>>>>>>>>>>>  reboot \n"
