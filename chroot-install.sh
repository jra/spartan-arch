#!/bin/bash

# This will be ran from the chrooted env.

user=$1
password=$2
fast=$3

# setup mirrors
if [ "$fast" -eq "1"]
then
    echo 'Setting up mirrors'
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
    rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
else
    echo 'Skipping mirror ranking because fast'
fi

# setup timezone
echo 'Setting up timezone'
timedatectl set-ntp true
ln -s /usr/share/zoneinfo/America/Denver /etc/localtime
timedatectl set-timezone America/Denver
hwclock --systohc

# setup locale
echo 'Setting up locale'
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# setup hostname
echo 'Setting up hostname'
echo 'blanca' > /etc/hostname

# build
echo 'Building'
mkinitcpio -p linux

# install bootloader
echo 'Installing bootloader'
pacman -S grub --noconfirm
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# install Xorg
echo 'Installing Xorg'
pacman -S --noconfirm xorg xorg-xinit xterm

# install virtualbox guest modules
echo 'Installing VB-guest-modules'
pacman -S --noconfirm virtualbox-guest-utils xf86-video-vmware

# vbox modules
echo 'vboxsf' > /etc/modules-load.d/vboxsf.conf

# install dev envt.
echo 'Installing dev environment'
pacman -S --noconfirm base-devel
pacman -S --noconfirm zsh tmux
pacman -S --noconfirm gnupg
pacman -S --noconfirm git emacs vim
pacman -S --noconfirm wget curl openssh openssl
pacman -S --noconfirm tree firefox ipython
#nodejs npm perl
#i3 dmenu
#pacman -S --noconfirm chromium autojump mlocate the_silver_searcher
#pacman -S --noconfirm ttf-hack lxterminal nitrogen ntp dhclient keychain
#pacman -S --noconfirm python-pip go go-tools pkg-config
#npm install -g jscs jshint bower grunt
#pip install pipenv bpython ipython

# install req for pacaur & cower
#echo 'Installing dependencies'
#pacman -S --noconfirm expac yajl

# user mgmt
echo 'Setting up user'
read -t 1 -n 1000000 discard      # discard previous input
echo 'root:'$password | chpasswd
useradd -m -G wheel -s /bin/zsh $user
touch /home/$user/.zshrc
chown $user:$user /home/$user/.zshrc
mkdir /home/$user/prj
chown $user:$user /home/$user/prj
mkdir /home/$user/wrk
chown $user:$user /home/$user/wrk
mkdir /home/$user/xfer
chown $user:$user /home/$user/xfer
#mkdir /home/$user/org
#chown $user:$user /home/$user/org
#mkdir /home/$user/workspace
#chown $user:$user /home/$user/workspace
echo $user:$password | chpasswd
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

# enable services
systemctl enable ntpdate.service

# preparing post install
wget https://github.com/jra/spartan-arch/raw/master/post-install.sh -O /home/$user/post-install.sh
chown $user:$user /home/$user/post-install.sh

echo 'Done'
