#!/bin/sh

clear
set -xe

echo "y" | /usr/bin/pacman -Scc --noconfirm >/dev/null 2>&1
pacman -Sy artix-keyring --noconfirm >/dev/null 2>&1
pacman-key --populate artix >/dev/null 2>&1
pacman -Sy >/dev/null 2>&1

hash parted >/dev/null 2>&1 || pacman -S --noconfirm parted >/dev/null 2>&1
hash nvim >/dev/null 2>&1 || pacman -S --noconfirm neovim >/dev/null 2>&1

parted -s /dev/vda mklabel msdos
parted -s -a optimal /dev/vda mkpart "primary" "ext4" "0%" "100%"
parted -s /dev/vda set 1 boot on
parted -s /dev/vda set 1 lvm on
parted -s /dev/vda align-check optimal 1

cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 10000 --use-urandom --verify-passphrase luksFormat /dev/vda1
cryptsetup luksOpen /dev/vda1 lvm-system

pvcreate /dev/mapper/lvm-system
vgcreate lvmSystem /dev/mapper/lvm-system

lvcreate --contiguous y --size 250M lvmSystem --name volBoot
lvcreate --contiguous y --size 2G lvmSystem --name volSwap
lvcreate --contiguous y --extents +100%FREE lvmSystem --name volRoot

mkfs.fat -n BOOT /dev/lvmSystem/volBoot
mkswap -L SWAP /dev/lvmSystem/volSwap
mkfs.ext4 -L ROOT /dev/lvmSystem/volRoot

swapon /dev/lvmSystem/volSwap
mount /dev/lvmSystem/volRoot /mnt
mount --mkdir /dev/lvmSystem/volBoot /mnt/boot

sed -i -e "s/    prepare_bootloader(fw_type)/    return None/g" /usr/lib/calamares/modules/bootloader/main.py

sed -i "s/\-gpt/\- gpt\n\    -vmd/" /etc/calamares/modules/partition.conf
sed -i "s/\-gpt/\- gpt\n\    -vmd/" /etc/calamares-offline/modules/partition.conf
sed -i "s/\-gpt/\- gpt\n\    -vmd/" /etc/calamares-online/modules/partition.conf

(cd /mnt) &
(cd /mnt/boot) &

calamares-config-switcher && sed -i -n -e "/^#/p" /mnt/etc/fstab

fstabgen -Up /mnt > /mnt/etc/fstab
sed -i -n -e "/^#/p" /mnt/etc/fstab

echo -e "tmpfs\t/tmp\ttmpfs\trw,nosuid,nodev,relatime,size=1G,mode=1777\t0\t0" >> /mnt/etc/fstab

artix-chroot /mnt passw

echo -e "pt_PT.UTF-8 UTF-8" >> /mnt/etc/locale.gen
artix-chroot /mnt locale-gen
echo "LANG=pt_PT.UTF-8" > /mnt/etc/locale.conf
# export "LANG=pt_PT.UTF-8
echo "LC_ADDRESS=pt_PT.UTF-8" >> /mnt/etc/locale.conf
echo "LC_IDENTIFICATION=pt_PT.UTF-8" >> /mnt/etc/locale.conf
echo "LC_MEASUREMENT=pt_PT.UTF-8" >> /mnt/etc/locale.conf
echo "LC_MONETARY=pt_PT.UTF-8" >> /mnt/etc/locale.conf
echo "LC_NAME=pt_PT.UTF-8" >> /mnt/etc/locale.conf
echo "LC_NUMERIC=pt_PT.UTF-8" >> /mnt/etc/locale.conf
echo "LC_PAPER=pt_PT.UTF-8" >> /mnt/etc/locale.conf
echo "LC_TELEPHONE=pt_PT.UTF-8" >> /mnt/etc/locale.conf
echo "LC_TIME=pt_PT.UTF-8" >> /mnt/etc/locale.conf
echo "LC_COLLATE=C" >> /mnt/etc/locale.conf
# export LC_COLLATE="C

artix-chroot /mnt ln -sf /usr/share/zoneinfo/Portugal /etc/localtime

echo "hostname=\"4rt1x\"" > /mnt/etc/conf.d/hostname

sed -s 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt keyboard keymap lvm2 resume filesystems fsck usr)/g' -i /mnt/etc/mkinitcpio.conf
 
artix-chroot /mnt pacman -Rc --noconfirm artix-grub-theme
artix-chroot /mnt pacman -Rc --noconfirm linux linux-headers
artix-chroot /mnt pacman -S --noconfirm linux-hardened linux-hardened-headers
artix-chroot /mnt pacman -S --noconfirm openssl openssl-1.1 pacman lvm2 cryptsetup nano glibc mkinitcpio
artix-chroot /mnt mkinitcpio -p linux-hardened
artix-chroot /mnt pacman -S --noconfirm grub

cryptuuid=$(blkid -s UUID -o value /dev/vda1)
swapuuid=$(blkid -s UUID -o value /dev/lvmSystem/volSwap)
sed -s "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"\
cryptdevice=UUID=${cryptuuid}:lvm-system loglevel=3 quiet resume=UUID=${swapuuid} net.ifnames=0 lsm=lockdown,yama,apparmor,bpf\"/g" -i /mnt/etc/default/grub
sed -s "s/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g" -i /mnt/etc/default/grub

artix-chroot /mnt ln -sf /etc/runit/sv/dmeventd /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/dbus /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/haveded /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/cronie /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/ntpd /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/acpid /etc/runit/runsvdir/current

artix-chroot /mnt grub-install --target=i386-pc --boot-directory=/boot --bootloader-id=artix --recheck /dev/vda

artix-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

umount -R /mnt
swapoff -a
sync
exit
