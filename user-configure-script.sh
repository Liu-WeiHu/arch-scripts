#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# 检查是否以root用户运行
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n$CER 请以root用户运行此脚本！"
    exit 1
fi

# 检查网络连接
echo -e "\n$CNT 检查网络连接..."
ping -c 3 www.baidu.com >/dev/null
if [ $? -eq 0 ]; then
    echo -e "\n$COK 网络已连接"
else
    echo -e "\n$CER 网络未连接，请先连接网络后再运行此脚本！"
    echo -e "    提示：您可以使用 nmtui 或 nmcli 配置网络连接"
    exit 1
fi

# 配置 pacman
echo -e "\n$CNT 配置 pacman..."
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i '/Color/a\\ILoveCandy' /etc/pacman.conf
sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# 添加 archlinuxcn 源
cat >>/etc/pacman.conf <<EOF

[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF

# 更新系统并安装 archlinuxcn-keyring
echo -e "\n$CNT 更新系统并安装 archlinuxcn 密钥..."
pacman -Sy
pacman-key --lsign-key "farseerfc@archlinux.org" || true
pacman -S --noconfirm archlinuxcn-keyring || true

# 如果密钥安装失败，则重新初始化密钥
read -rep $'[\e[1;37mATTENTION\e[0m] - ArchlinuxCn 密钥安装是否成功？(y/n) ' KEY
if [[ $KEY == "N" || $KEY == "n" ]]; then
    echo -e "$CNT 重新初始化密钥..."
    rm -rf /etc/pacman.d/gnupg
    pacman-key --init
    pacman-key --populate archlinux archlinuxcn
    echo -e "\n$CAC 密钥初始化完成"
fi

# 安装 AUR 助手
echo -e "\n$CNT 安装 paru..."
pacman -S --noconfirm paru
sed -i 's/#BottomUp/BottomUp/' /etc/paru.conf
echo -e "\n$CAC paru 安装配置完成"

# 添加用户
echo -e "\n$CNT 添加用户..."
read -rep $'[\e[1;37mATTENTION\e[0m] - 请输入用户名: ' UUSER
useradd -m -G wheel $UUSER

read -rep $'[\e[1;37mATTENTION\e[0m] - 请输入用户密码: ' PASSWD
echo -e "${PASSWD}\n${PASSWD}" | passwd $UUSER

# 配置 sudo 权限
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
echo -e "\n$CAC 用户添加完成"

# 安装字体
echo -e "\n$CNT 安装字体..."
pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono ttf-lxgw-wenkai ttf-lxgw-wenkai-mono
echo -e "\n$CAC 字体安装完成"

# 安装音频系统
echo -e "\n$CNT 安装 pipewire 音频系统..."
pacman -S --noconfirm pipewire wireplumber pipewire-pulse gst-plugin-pipewire pipewire-alsa pipewire-audio pipewire-jack
echo -e "\n$CAC pipewire 安装完成"

# 安装集成显卡驱动
echo -e "\n$CNT 安装集成显卡驱动..."
pacman -S --noconfirm mesa libva-utils vulkan-icd-loader vulkan-tools

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
        echo "输入错误，请重新输入"
        ;;
    esac
done
echo -e "\n$CAC 显卡驱动安装完成"

# 安装输入法
echo -e "\n$CNT 安装中文输入法..."
pacman -S --noconfirm fcitx5-im fcitx5-chinese-addons fcitx5-pinyin-zhwiki fcitx5-pinyin-moegirl

# 修复 fstab
echo -e "\n$CNT 优化 fstab..."
sed -i 's/subvolid=[0-9]\{3\}/nodiscard/g' /etc/fstab
echo -e "\n$CAC fstab 优化完成"

# 配置网络管理器
echo -e "\n$CNT 配置 NetworkManager..."
mkdir -p /etc/NetworkManager/conf.d/
cat <<EOF >/etc/NetworkManager/conf.d/20-connectivity.conf
[connectivity]
enabled=false
EOF
echo -e "\n$CAC NetworkManager 配置完成"

# 设置包缓存清理
echo -e "\n$CNT 设置自动清理包缓存..."
systemctl enable paccache.timer
echo -e "\n$CAC 包缓存清理设置完成"

# 网络优化
echo -e "\n$CNT 优化网络设置..."
cat <<EOF >/etc/sysctl.d/20-fast.conf
net.ipv4.tcp_fastopen = 3
EOF

cat <<EOF >/etc/sysctl.d/30-bbr.conf
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
EOF

modprobe tcp_bbr
echo -e "\n$CAC 网络优化配置完成"

# 配置 btrfs swapfile
echo -e "\n$CNT 创建 swap 文件..."
read -rep $'[\e[1;37mATTENTION\e[0m] - 请输入 swap 文件大小 (单位: GB，默认: 16): ' SWAP_SIZE
SWAP_SIZE=${SWAP_SIZE:-16}

btrfs filesystem mkswapfile --size ${SWAP_SIZE}g --uuid clear /swap/swapfile
swapon /swap/swapfile

# 更新 fstab 添加 swapfile
cat <<EOF >>/etc/fstab

# swapfile
/swap/swapfile none swap defaults 0 0
EOF
echo -e "\n$CAC swap 文件配置完成"

# 将脚本移动到用户目录
if [ -d /root/arch-scripts ]; then
    cp -r /root/arch-scripts /home/$UUSER/
    chown -R $UUSER:$UUSER /home/$UUSER/arch-scripts
fi

echo -e "\n$COK 系统配置完成！以下是系统信息："
echo -e "\n文件系统挂载情况："
df -h

echo -e "\n分区情况："
lsblk

echo -e "\n$CAT 您已成功安装 Arch Linux，请使用以下命令重启系统："
echo -e "    exit"
echo -e "    umount -R /mnt"
echo -e "    reboot"

# 标记用户配置完成
touch /root/.user_setup_completed
