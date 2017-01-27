#!/bin/bash
CWD=$(pwd)
INIT=$(mktemp -d)

cd $INIT

mkdir -p {boot,bin,dev,etc,lib,lib/arm-linux-gnueabihf,lib64,proc,root,sbin,sys,sdcard,squashfs,upper,overlay}
cp -a /dev/{null,console,tty,mmcblk0,ttyAMA0,ttyS0} ./dev/
cp $CWD/initscript ./init
chmod +x ./init
cp $CWD/simple.script ./simple.script
chmod +x ./simple.script

apt-get update
apt-get download busybox-static
dpkg -x *busybox-static*deb ./
rm *busybox-static*deb
./bin/busybox --install ./bin/

cp /lib/arm-linux-gnueabihf/ld-linux-armhf.so.3 ./lib/arm-linux-gnueabihf/ld-linux-armhf.so.3
cp /lib/arm-linux-gnueabihf/libc.so.6 ./lib/arm-linux-gnueabihf/libc.so.6
cp /lib/arm-linux-gnueabihf/libnss_dns.so.2 ./lib/arm-linux-gnueabihf/libnss_dns.so.2
cp /lib/arm-linux-gnueabihf/libnss_files.so.2 ./lib/arm-linux-gnueabihf/libnss_files.so.2
cp /lib/arm-linux-gnueabihf/libnss_mdns4_minimal.so.2 ./lib/arm-linux-gnueabihf/libnss_mdns4_minimal.so.2
cp /lib/arm-linux-gnueabihf/libresolv.so.2 ./lib/arm-linux-gnueabihf/libresolv.so.2

find . -print0 | cpio --null -ov --format=newc | gzip -9 > $CWD/enginfo.gz

cp $CWD/shellscript ./init
chmod +x ./init
find . -print0 | cpio --null -ov --format=newc | gzip -9 > $CWD/enginfo-shell.gz

cd $CWD
