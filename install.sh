#!/bin/bash

IMAGE="rpi3.img"
SQUASHFSIMG="rpi3.squashfs.img"

echo "Checking for root .. "
if [ `id -u` != 0 ]; then
    echo "Script needs to be run as root."
    exit 1
else
    echo "Root user detected"
fi

do_apps() {
  echo "Setting up environment"
  apt-get -qq update
  apt-get -qq -y install psmisc libc6-dev kpartx parted dosfstools cdebootstrap squashfs-tools
}

check_free_space() {
  FREE=$(df | grep "/$" | awk '{print $4}')
  if [ $FREE -gt 2048000 ]; then
    return 0
  else
    echo "Filesystem too small"
    exit
  fi
}

check_image_exist() {
  if [ -f "$IMAGE" ]; then
    echo "Conflicting image found. Please remove/rename."
    exit
  else
    return 0
  fi

  if [ -f "$SQUASHFSIMG" ]; then
    echo "Conflicting image found. Please remove/rename."
    exit
  else
    return 0
  fi
}

do_create_image() {
  check_free_space
  check_image_exist
  echo "Creating disk image of 2GB"
  dd if=/dev/zero of="$IMAGE" bs=1M count=2000 iflag=fullblock

  # partitioning the disk image
  echo "Partitioning image"
  (echo o; echo n; echo p; echo 1; echo; echo +128M; echo a; echo t; echo 6; echo n; echo p; echo 2; echo; echo; echo w) | fdisk "$IMAGE"
  LOOP_DEVICE=$(kpartx -av $IMAGE | grep p2 | cut -d " " -f8 | awk '{print$1}')

  partprobe $LOOP_DEVICE

  BOOTPART=$(echo $LOOP_DEVICE | grep dev | cut -d "/" -f3 | awk '{print$1}')p1
  BOOTPART=/dev/mapper/$BOOTPART
  ROOTPART=$(echo $LOOP_DEVICE | grep dev | cut -d "/" -f3 | awk '{print$1}')p2
  ROOTPART=/dev/mapper/$ROOTPART
  echo "Creating filesystems"
  mkdosfs -n BOOT $BOOTPART
  mkfs.ext4 -b 4096 -L rootfs $ROOTPART

  echo "Image successfully created."
  sync
  return 0
}

do_mount_root() {
  mount -t ext4 -o sync $ROOTPART $BOOTSTRAP
  if [ $? -gt 0 ]; then
    echo "Troubles mounting the system"
    exit
  fi
}

do_bootstrap() {
  BOOTSTRAP=$(mktemp -d)
  INCLUDE="--include=kbd,locales,keyboard-configuration,console-setup"
  MIRROR="http://mirror.csclub.uwaterloo.ca/debian"
  RELEASE="jessie"
  do_mount_root

  cdebootstrap --arch armhf ${RELEASE} $BOOTSTRAP $MIRROR ${INCLUDE} --allow-unauthenticated
  if [ $? -gt 0 ]; then
    echo "Problems bootstrapping the OS"
    exit
  fi
  echo "Successfully bootstrapped"
  sync
  do_mount_rest
}

do_mount_rest() {
  mount -t vfat -o sync $BOOTPART $BOOTSTRAP/boot
  mount -t proc proc $BOOTSTRAP/proc
  mount -t sysfs sysfs $BOOTSTRAP/sys
  mount --bind /dev/pts $BOOTSTRAP/dev/pts
}

do_install_system() {
  # change root password to debian
  chroot $BOOTSTRAP sh -c "echo root:debian | chpasswd"
  chroot $BOOTSTRAP adduser --disabled-password --gecos "" --quiet kiosk
  # chroot $BOOTSTRAP chown kiosk:kiosk /home/kiosk
  # add repositories
  chroot $BOOTSTRAP sh -c "wget -q -O - http://archive.raspberrypi.org/debian/raspberrypi.gpg.key | apt-key add -"
  chroot $BOOTSTRAP sh -c "wget -q -O - http://r.uwaterfowl.ca/uwaterfowl.key | apt-key add -"
  chroot $BOOTSTRAP sh -c "wget -q -O - http://apt.monkey-project.com/monkey.key | apt-key add -"
  sed -i $BOOTSTRAP/etc/apt/sources.list -e "s/main/main contrib non-free/"
  echo "deb http://archive.raspberrypi.org/debian/ $RELEASE main" >> $BOOTSTRAP/etc/apt/sources.list
  echo "deb http://r.uwaterfowl.ca/debian/ $RELEASE main" >> $BOOTSTRAP/etc/apt/sources.list
  echo "deb http://apt.monkey-project.com/raspbian $RELEASE main" >> $BOOTSTRAP/etc/apt/sources.list

  cp -R config/* $BOOTSTRAP/

  DEFAULT_LOCALE="\"en_US.UTF-8\" \"en_US:en\""

  #maybe not needed?
  cp /etc/hosts $BOOTSTRAP/etc/hosts

  sed -i $BOOTSTRAP/lib/udev/rules.d/75-persistent-net-generator.rules -e 's/KERNEL\!="eth\*|ath\*|wlan\*\[0-9\]/KERNEL\!="ath\*/'
  chroot $BOOTSTRAP dpkg-divert --add --local /lib/udev/rules.d/75-persistent-net-generator.rules

  # configuring system
  chroot $BOOTSTRAP dpkg-reconfigure -f noninteractive locales
  chroot $BOOTSTRAP locale-gen LANG="$DEFAULT_LOCALE"
  chroot $BOOTSTRAP dpkg-reconfigure -f noninteractive tzdata
  chroot $BOOTSTRAP dpkg-reconfigure -f noninteractive keyboard-configuration
  chroot $BOOTSTRAP dpkg-reconfigure -f noninteractive console-setup

  #updating system
  echo "updating system"
  chroot $BOOTSTRAP apt-get update
  chroot $BOOTSTRAP apt-get -y upgrade
  chroot $BOOTSTRAP apt-get -y install libraspberrypi-bin raspberrypi-bootloader raspi-copies-and-fills
  chroot $BOOTSTRAP apt-get -y install dbus fake-hwclock psmisc ntp openssh-server policykit-1 ca-certificates monkey
  chroot $BOOTSTRAP apt-get -y install icewm-lite unclutter chromium-browser lsb-release libexif12 xserver-xorg xorg xserver-xorg-video-fbdev x11-utils iptables
  chroot $BOOTSTRAP apt-get -y install linux-image-4.8.6-uwaterfowl linux-firmware-image-4.8.6-uwaterfowl linux-headers-4.8.6-uwaterfowl
  chroot $BOOTSTRAP apt-get clean
  chroot $BOOTSTRAP apt-get autoremove -y

  sed -i 's/^allowed_users=console$/allowed_users=anybody/' $BOOTSTRAP/etc/X11/Xwrapper.config

  chroot $BOOTSTRAP chown -R kiosk:kiosk /home/kiosk

  sed -i 's/Port 22/Port 35147/' $BOOTSTRAP/etc/ssh/sshd_config
  chroot $BOOTSTRAP service monkey stop
  chroot $BOOTSTRAP service dbus stop

  chroot $BOOTSTRAP crontab -u root /root/cron

  sync
  # done
  echo "Done with the image"
  sync
}

do_makesquashfs() {
  echo "Making squashfs image."
  mksquashfs $BOOTSTRAP $SQUASHFSIMG
}

do_unmount() {
  fuser -av $BOOTSTRAP
  fuser -kv $BOOTSTRAP
  umount $BOOTSTRAP/proc
  umount $BOOTSTRAP/sys
  umount $BOOTSTRAP/dev/pts

  do_makesquashfs

  umount $BOOTSTRAP/boot
  umount $BOOTSTRAP
  kpartx -d $IMAGE
}

do_apps
do_create_image
do_bootstrap
do_install_system
do_unmount
