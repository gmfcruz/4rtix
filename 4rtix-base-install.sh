#!/bin/sh

_DISK=""			# Target Disk
_KTPASS="123"			# Encryption Password
_USER="groot"			# User name
_UPASS="123"			# User Password
_DESK="xfce xfce-goodies"	# Desktop (blank if you dont whant desktop installation)
_LOC="Portugal"			# Location/Region
_KMAP="pt-latin1"		# Keymap
_SSID=""			# SSID wifi
_WPASS=""			# Wifi password
_KERN="linux-lts"		# Kernel

clear

hash dmidecode	>/dev/null 2>&1 || pacman -S --noconfirm dmidecode 	>/dev/null 2>&1
hash parted	>/dev/null 2>&1 || pacman -S --noconfirm parted		>/dev/null 2>&1
hash nvim	>/dev/null 2>&1 || pacman -S --noconfirm neovim		>/dev/null 2>&1

case $(grep vendor /proc/cpuinfo) in
*"Intel"*)
        _UCOD="intel-ucode"
        ;;
*"Amd"*)
        _UCOD="amd-ucode"
        ;;
esac

_MEM="$(dmidecode --type 19| grep Range| awk '{ print $3 }')"
_HST="$(dmidecode -s system-product-name)"


ln -sf /usr/share/zoneinfo/"${_LOC}" /etc/localtime
hwclock -w

echo "y" | /usr/bin/pacman -Scc --noconfirm	>/dev/null 2>&1
pacman -Sy artix-keyring --noconfirm		>/dev/null 2>&1
pacman-key --populate artix			>/dev/null 2>&1
pacman -Sy					>/dev/null 2>&1

set -xe
[ -d "/sys/firmware/efi" ] && _EFI="1"
[ "${_EFI}" ] && parted -s		/dev/${_DISK} mklabel gpt
[ "${_EFI}" ] && parted -s		/dev/${_DISK} mkpart "BIOS" 0% 1MiB
[ "${_EFI}" ] && parted -s -a optimal 	/dev/${_DISK} set 1 bios_grub on
[ "${_EFI}" ] && parted -s -a optimal 	/dev/${_DISK} mkpart "EFI" ext4 1MiB 250MiB
[ "${_EFI}" ] && parted -s -a optimal 	/dev/${_DISK} set 2 esp on
[ "${_EFI}" ] && parted -s -a optimal 	/dev/${_DISK} mkpart "CRYPT" ext4 250MiB 100%
[ "${_EFI}" ] && parted -s -a optimal 	/dev/${_DISK} set 3 lvm on

[ "${_EFI}" ] || parted -s		/dev/${_DISK} mklabel msdos
[ "${_EFI}" ] || parted -s -a optimal	/dev/${_DISK} mkpart "primary" "ext4" "0%" "100%"
[ "${_EFI}" ] || parted -s -a optimal	/dev/${_DISK} set 1 boot on
[ "${_EFI}" ] || parted -s -a optimal	/dev/${_DISK} set 1 lvm on
[ "${_EFI}" ] || parted -s 		/dev/${_DISK} align-check optimal 1

[ "${_EFI}" ] && echo -ne "${_KPASS}" | cryptsetup -v -q --cipher aes-xts-plain64 --key-size 512 --hash sha512 --pbkdf argon2i --iter-time 10000 --use-urandom --verify-passphrase luksFormat /dev/${_DISK}3 -d -

[ "${_EFI}" ] || echo -ne "${_KPASS}" | cryptsetup -v -q --cipher aes-xts-plain64 --key-size 512 --hash sha512 --pbkdf argon2i --iter-time 10000 --use-urandom --verify-passphrase luksFormat /dev/${_DISK}1 -d -

echo -ne "${_KPASS}" | cryptsetup open /dev/${_DISK}1 lvm-system -d -

pvcreate /dev/mapper/lvm-system
vgcreate lvmSystem /dev/mapper/lvm-system

lvcreate --contiguous y --size 		250M lvmSystem		--name volBoot
lvcreate --contiguous y --size 		${_MEM}G lvmSystem	--name volSwap
lvcreate --contiguous y --extents 	+100%FREE lvmSystem	--name volRoot

mkfs.fat	-n BOOT /dev/lvmSystem/volBoot
mkswap		-L SWAP /dev/lvmSystem/volSwap
mkfs.ext4 	-L ROOT /dev/lvmSystem/volRoot

swapon /dev/lvmSystem/volSwap
mount /dev/lvmSystem/volRoot /mnt
[ "${_EFI}" ] || mount --mkdir /dev/lvmSystem/volBoot /mnt/boot
[ "${_EFI}" ] && mount --mkdir /dev/${_DISK}2 /mnt/efi

_basestrap=(base base-devel runit elogind-runit linux-firmware ${_UCOD} haveged-runit backlight-runit libpwquality sysstat cryptsetup-runit rsync-runit nfs-utils nfs-utils-runit neovim ntp-runit acpid-runit dmidecode glibc mkinitcpio dhcpcd-runit haveged-runit udiskie less mlocate device-mapper-runit openssl metalog-runit firejail ntfs-3g logrotate lvm2 man-db man-pages usbguard-runit apparmor-runit tlp-runit bind cronie-runit git wget grub)

[ "${_EFI}" ] && _basestrap=(efibootmgr) # EFI system

_basestrap+=(${_KERN} ${_KERN}-headers) # Kernel parameter

[ "${_DESK}" ] && _basestrap=(${_DESK}) # Desktop parameter

_basestrap+=(networkmanager-runit wpa_supplicant-runit networkmanager-applet iw) # Network

_basestrap+=(libvirt-runit virt-manager qemu bridge-utils vde2) # Virtualization

_basestrap+=(audit-runit) # Audit system

_basestrap+=(nftables-runit) # Firewall

_basestrap+=(alsa-utils pulseaudio-alsa) # Sound

_basestrap+=(libva-intel-driver mesa-vdpau vdpauinfo vulkan-intel) # Xorg

basestrap "/mnt" "${_basestrap[@]}" # Install system

artix-chroot /mnt ln -sf /usr/share/zoneinfo/"${_LOC}" /etc/localtime
artix-chroot /mnt hwclock -w

fstabgen -pU /mnt > /mnt/etc/fstab

sed -i 's/rw,relatime,stripe=4/ro,noatime,nodev,noexec,nosuid,stripe=4/' /mnt/etc/fstab
sed -i 's/rw,noatime\t0 1/defaults,noatime\t0 1/' /mnt/etc/fstab
echo -e "# /dev/shm: shared application memory\ntmpfs\t/dev/shm\ttmpfs\tdefaults,noatime,nodev,nosuid,noexec,size=$((${_MEM}/2))G,mode=1771,uid=root,gid=shm\t0 0\n" >> /mnt/etc/fstab
echo -e "# /tmp: temporary files\ntmpfs\t/tmp\t\ttmpfs\tdefaults,noatime,nodev,noexec,nosuid,size=8192M,mode=1777\t0 0\n" >> /mnt/etc/fstab
echo -e "# /var/tmp: temporary files (preserved)\n/tmp\t/var/tmp\tnone\tdefaults,noatime,nodev,noexec,nosuid,bind\t0 0\n" >> /mnt/etc/fstab
echo -e "# /var/cache/makepkg: temporary build dir\ntmpfs\t/var/cache/makepkg\t\ttmpfs\tdefaults,noatime,nodev,nosuid,size=4096M,mode=1771,uid=root,gid=wheel\t0 0\n" >> /mnt/etc/fstab
echo -e "# /proc: kernel and process information\nproc\t/proc\t\tproc\tnodev,noexec,nosuid,gid=wheel\t0 0" >> /mnt/etc/fstab

sed -s 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block \
encrypt keyboard keymap lvm2 resume filesystems fsck usr)/g' -i /mnt/etc/mkinitcpio.conf

sed -s 's/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g' -i /mnt/etc/default/grub
/usr/bin/sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/" /mnt/etc/default/grub

[ "${_EFI}" ] && cryptuuid=$(blkid -s UUID -o value ${DISK}3)
[ "${_EFI}" ] || cryptuuid=$(blkid -s UUID -o value ${DISK}1)
swapuuid=$(blkid -s UUID -o value /dev/lvmSystem/volSwap)

sed -s "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"\
cryptdevice=UUID=${cryptuuid}:lvm-system quiet loglevel=3 resume=UUID=${swapuuid} net.ifnames=0 lsm=lockdown,yama,apparmor,bpf\"/g" \
        -i /mnt/etc/default/grub

# Locking grub
GRUB_PASSWD=$(echo -e "${_UPASS}\n${_UPASS}\n" | /mnt/usr/sbin/grub-mkpasswd-pbkdf2 | tail -n 1 | cut -d ' ' -f 7)
cat > /mnt/etc/grub.d/05_superusers << EOL
cat << EOF
set superusers="${_USER}"
password_pbkdf2 ${_USER} ${GRUB_PASSWD}
EOF
EOL
chmod 0700 /mnt/etc/grub.d/05_superusers
/usr/bin/sed -i "s/ \${CLASS} / \${CLASS} --users \'\' /" /mnt/etc/grub.d/10_linux

[ "${_EFI}" ] && artix-chroot /mnt sh -c 'grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=grub --recheck'
[ "${_EFI}" ] || partprobe "${_DISK}" 
[ "${_EFI}" ] || artix-chroot /mnt sh -c "grub-install --target=i386-pc '${_DISK}'"
 
artix-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

_KEY=$(openssl rand -hex 8)
dd bs=512 count=4 if=/dev/random of=/mnt/root/"${_KEY}" iflag=fullblock
chmod 000 /mnt/root/"${_KEY}"
[ "${_EFI}" ] && cryptsetup -v luksAddKey /dev/${_DISK}3 /mnt/root/"${_KEY}"
[ "${_EFI}" ] || cryptsetup -v luksAddKey /dev/${_DISK}1 /mnt/root/"${_KEY}"

sed -i "s/FILES=.*/FILES=(\/root\/'${_KEY}')/" /mnt/etc/mkinitcpio.conf
sed -s "s/lvm-system/lvm-system cryptkey=rootfs:\/root\/'${_KEY}'/" -i /mnt/etc/default/grub

artix-chroot /mnt mkinitcpio -p "${_KERN}"

chmod 600 /boot/initramfs-linux*

artix-chroot /mnt passwd

sed -i 's/^#${_LOC}\.UTF/${_LOC}\.UTF/' /mnt/etc/locale.gen
sed -i 's/^en_EN\.UTF/#en_EN\.UTF/' /mnt/etc/locale.gen
artix-chroot /mnt locale-gen
echo "LANG=${_LOC}.UTF-8" > /mnt/etc/locale.conf
artix-chroot /mnt sh -c 'export "LANG='${_LOC}'.UTF-8"'
echo "LC_ADDRESS=${_LOC}.UTF-8" >> /mnt/etc/locale.conf
echo "LC_IDENTIFICATION=${_LOC}.UTF-8" >> /mnt/etc/locale.conf
echo "LC_MEASUREMENT=${_LOC}.UTF-8" >> /mnt/etc/locale.conf
echo "LC_MONETARY=${_LOC}.UTF-8" >> /mnt/etc/locale.conf
echo "LC_NAME=${_LOC}.UTF-8" >> /mnt/etc/locale.conf
echo "LC_NUMERIC=${_LOC}.UTF-8" >> /mnt/etc/locale.conf
echo "LC_PAPER=${_LOC}.UTF-8" >> /mnt/etc/locale.conf
echo "LC_TELEPHONE=${_LOC}.UTF-8" >> /mnt/etc/locale.conf
echo "LC_TIME=${_LOC}.UTF-8" >> /mnt/etc/locale.conf
echo "LC_COLLATE=C" >> /mnt/etc/locale.conf
artix-chroot /mnt sh -c 'export LC_COLLATE="C"'

echo "hostname=\"${_HST}\"" > /mnt/etc/conf.d/hostname

artix-chroot /mnt pacman -Syy

artix-chroot /mnt ln -sf /etc/runit/sv/dmeventd /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/dbus /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/haveded /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/cronie /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/ntpd /etc/runit/runsvdir/current
artix-chroot /mnt ln -sf /etc/runit/sv/acpid /etc/runit/runsvdir/current

umount -R /mnt
swapoff -a
sync
exit
