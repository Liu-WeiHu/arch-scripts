#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n$CER Please run this script as root!"
    exit 1
fi

# Check network connection
echo -e "\n$CNT Checking network connection..."
ping -c 3 www.baidu.com >/dev/null
if [ $? -eq 0 ]; then
    echo -e "\n$COK Network connected"
else
    echo -e "\n$CER Network not connected, please connect to the network before running this script!"
    echo -e "    Tip: You can use nmtui or nmcli to configure network connection"
    exit 1
fi

# Configure pacman
echo -e "\n$CNT Configuring pacman..."
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i '/Color/a\\ILoveCandy' /etc/pacman.conf
sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Add archlinuxcn repository
cat >>/etc/pacman.conf <<EOF

[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF

# Update system and install archlinuxcn-keyring
echo -e "\n$CNT Updating system and installing archlinuxcn keys..."
pacman -Sy
pacman-key --lsign-key "farseerfc@archlinux.org" || true
pacman -S --noconfirm archlinuxcn-keyring || true

# If key installation fails, reinitialize keys
read -rep $'[\e[1;37mATTENTION\e[0m] - Was ArchlinuxCn key installation successful (default: y)? (y/n) ' KEY
KEY=${KEY:-y}
if [[ $KEY == "N" || $KEY == "n" ]]; then
    echo -e "$CNT Reinitializing keys..."
    rm -rf /etc/pacman.d/gnupg
    pacman-key --init
    pacman-key --populate archlinux archlinuxcn
    echo -e "\n$CAC Key initialization completed"
fi

# Install AUR helper
echo -e "\n$CNT Installing paru..."
pacman -S --noconfirm paru
sed -i 's/#BottomUp/BottomUp/' /etc/paru.conf
echo -e "\n$CAC paru installation and configuration completed"

# Add user
echo -e "\n$CNT Adding user..."
read -rep $'[\e[1;37mATTENTION\e[0m] - Please enter username: ' UUSER
useradd -m -G wheel $UUSER

read -rep $'[\e[1;37mATTENTION\e[0m] - Please enter user password: ' PASSWD
echo -e "${PASSWD}\n${PASSWD}" | passwd $UUSER

# Configure sudo permissions
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
echo -e "\n$CAC User added successfully"

# Install fonts
echo -e "\n$CNT Installing fonts..."
pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono ttf-twemoji
echo -e "\n$CAC Fonts installation completed"

# Install audio system
echo -e "\n$CNT Installing pipewire audio system..."
pacman -S --noconfirm pipewire wireplumber pipewire-pulse gst-plugin-pipewire pipewire-alsa pipewire-audio pipewire-jack
echo -e "\n$CAC pipewire installation completed"

# Install integrated graphics drivers
echo -e "\n$CNT Installing integrated graphics drivers..."
pacman -S --noconfirm mesa libva-utils vulkan-icd-loader vulkan-tools

echo -e "\n$CNT Please select your video card type, nvidia is not in the script...."
select graphics in "cpu-intel" "cpu-amd"; do
    case $graphics in
    "cpu-intel")
        pacman -S --noconfirm intel-media-driver vulkan-intel
        break
        ;;
    "cpu-amd")
        pacman -S --noconfirm libva-mesa-driver vulkan-radeon
        break
        ;;
    *)
        echo "Invalid input, please try again"
        ;;
    esac
done
echo -e "\n$CAC Graphics drivers installation completed"

# Install input method
echo -e "\n$CNT Installing Chinese input method..."
pacman -S --noconfirm fcitx5-im fcitx5-chinese-addons fcitx5-pinyin-zhwiki fcitx5-pinyin-moegirl

# Fix fstab
echo -e "\n$CNT Optimizing fstab..."
sed -i 's/subvolid=[0-9]\{3\}/nodiscard/g' /etc/fstab
echo -e "\n$CAC fstab optimization completed"

# Configure network manager
echo -e "\n$CNT Configuring NetworkManager..."
mkdir -p /etc/NetworkManager/conf.d/
cat <<EOF >/etc/NetworkManager/conf.d/20-connectivity.conf
[connectivity]
enabled=false
EOF
echo -e "\n$CAC NetworkManager configuration completed"

# Setup package cache cleaning
echo -e "\n$CNT Setting up automatic package cache cleaning..."
systemctl enable paccache.timer
echo -e "\n$CAC Package cache cleaning setup completed"

# Network optimization
echo -e "\n$CNT Optimizing network settings..."
cat <<EOF >/etc/sysctl.d/20-fast.conf
net.ipv4.tcp_fastopen = 3
EOF

cat <<EOF >/etc/sysctl.d/30-bbr.conf
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
EOF

modprobe tcp_bbr
echo -e "\n$CAC Network optimization configuration completed"

# Configure btrfs swapfile
echo -e "\n$CNT Creating swap file..."
read -rep $'[\e[1;37mATTENTION\e[0m] - Please enter swap file size (in GB, default: 16): ' SWAP_SIZE
SWAP_SIZE=${SWAP_SIZE:-16}

btrfs filesystem mkswapfile --size ${SWAP_SIZE}g --uuid clear /swap/swapfile
swapon /swap/swapfile

# Update fstab to add swapfile
cat <<EOF >>/etc/fstab

# swapfile
/swap/swapfile none swap defaults 0 0
EOF
echo -e "\n$CAC Swap file configuration completed"

# Move scripts to user directory
if [ -d /root/arch-scripts ]; then
    cp -r /root/arch-scripts /home/$UUSER/
    chown -R $UUSER:$UUSER /home/$UUSER/arch-scripts
fi

echo -e "\n$COK System configuration completed! System information:"
echo -e "\nFilesystem mount status:"
df -h

echo -e "\nPartition status:"
lsblk

# Mark user configuration as completed
touch /root/.user_setup_completed
