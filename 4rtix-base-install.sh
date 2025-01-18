#!/bin/sh

clear
set -xe

echo "s" | /usr/bin/pacman -Scc --noconfirm >/dev/null 2>&1
pacman -Sy artix-keyring --noconfirm >/dev/null 2>&1
pacman-key --populate artix >/dev/null 2>&1
pacman -Sy >/dev/null 2>&1

hash parted >/dev/null 2>&1 || pacman -S --noconfirm parted >/dev/null 2>&1
hash nvim >/dev/null 2>&1 || pacman -S --noconfirm neovim >/dev/null 2>&1

parted -s /dev/vda mklabel bios 
parted -s -a optimal /dev/vda mkpart "primary" "0%" "1MiB"
parted -s /dev/vda set 1 grub_bios on
parted -s -a optimal /dev/vda mkpart "primary" "ext4" "1MiB" "250MiB"
parted -s /dev/vda set 2 esp on
parted -s /dev/vda align-check optimal 1
parted -s -a optimal /dev/vda mkpart "primary" "ext4" "250MiB" "100%"
parted -s /dev/vda set 3 lvm on

cryptsetup -v --cipher aes-xts-plain64 --key-size 256 --hash sha256 --iter-time 2000 --use-urandom --verify-passphrase luksFormat /dev/vda2
cryptsetup luksOpen /dev/vda3 lvm-system

pvcreate /dev/mapper/lvm-system
vgcreate lvmSystem /dev/mapper/lvm-system
lvcreate -L 4G lvmSystem -n volSwap
lvcreate -l +100%FREE lvmSystem -n volRoot

mkswap /dev/lvmSystem/volSwap
mkfs.fat -n ESP /dev/vda2
mkfs.ext4 -L volRoot /dev/lvmSystem/volRoot

swapon /dev/lvmSystem/volSwap
mount /dev/lvmSystem/volRoot /mnt
mount --mkdir /dev/vda2 /mnt/efi

basestrap /mnt base base-devel mkinitcpio grub efibootmgr

fstabgen -Up /mnt >> /mnt/etc/fstab

echo "tmpfs	/tmp	tmpfs	nodev,nosuid,size=2G	0 0" >> /mnt/etc/fstab

artix-chroot /mnt echo -e "pt_PT.UTF-8 UTF-8" >> /etc/locale.gen
artix-chroot /mnt  locale-gen
artix-chroot /mnt echo LANG=pt_PT.UTF-8 > /etc/locale.conf
# artix-chroot /mnt export LANG=pt_PT.UTF-8

artix-chroot /mnt ln -s /usr/share/zoneinfo/Portugal /etc/localtime
artix-chroot /mnt echo "hostname=4rt1x" > /etc/conf.d/hostname

artix-chroot /mnt sed -i "s/FILES=(/FILES=(\/crypto_keyfile.bin/g" /etc/mkinitcpio.conf
artix-chroot /mnt sed -i "s/modconf block/modconf block encrypt lvm2 resume/g" /etc/mkinitcpio.conf

dd if=/dev/random of=/mnt/crypto_keyfile.bin bs=512 count=8 iflag=fullblock
cryptsetup luksAddKey /dev/vda2 /mnt/crypto_keyfile.bin
chmod 000 /mnt/crypto_keyfile.bin

artix-chroot /mnt mkinitcpio -p linux

artix-chroot /mnt passwd

artix-chroot /mnt pacman -S --noconfirm efibootmgr dosfstools freetype2 fuse2 gptfdisk libisoburn mtools os-prober iw memtest86+ wpa_supplicant

artix-chroot /mnt sed -i "s/quiet/quiet resume=UUID=`blkid -s UUID -o value /dev/lvmSystem/volSwap`/g" /etc/default/grub
sed -s 's/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g' -i /mnt/etc/default/grub
artix-chroot /mnt sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=`blkid -s UUID -o value /dev/vda2`:lvm-system\"/g" /etc/default/grub

artix-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=grub --recheck

artix-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

artix-chroot /mnt ln -sf /etc/runit/sv/dmeventd /etc/runit/runsvdir/default
artix-chroot /mnt ln -sf /etc/runit/sv/dbus /etc/runit/runsvdir/default
artix-chroot /mnt ln -sf /etc/runit/sv/cronie /etc/runit/runsvdir/default

artix-chroot /mnt pacman -S --noconfirm networkmanager networkmanager-openrc networkmanager-openvpn network-manager-applet

artix-chroot /mnt ln -sf /etc/runit/sv/networkmanager /etc/runit/runsvdir/default

artix-chroot /mnt wpa_passphrase "1PM4" "G0nc41oH31g4L30n0rL0v331nt3rn3t" > /etc/wpa_supplicant/wpa_supplicant.conf
artix-chroot /mnt echo "modules_INTERFACE_ID=\"wpa_supplicant dhcpcd\"" >> /etc/conf.d/net

artix-chroot /mnt echo "carrier_timeout_INTERFACE_ID=5" >> /etc/conf.d/net

artix-chroot /mnt pacman -S --noconfirm ntp-runit acpid-runit syslog-ng-runit

artix-chroot /mnt ln -sf /etc/runit/runsvdir/default /etc/runit/sv/ntpd
artix-chroot /mnt ln -sf /etc/runit/runsvdir/default /etc/runit/sv/acpid
artix-chroot /mnt ln -sf /etc/runit/runsvdir/default /etc/runit/sv/syslog-ng

artix-chroot /mnt pacman -S --noconfirm artix bash-completion lsof strace wget htop mc zip samba unrar p7zip unzip hdparm smartmontools hwinfo dmidecode whois rsync nmap tcpdump inetutils net-tools ndisc6

umount -R /mnt
swapoff -a
exit
