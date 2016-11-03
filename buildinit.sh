#!/bin/bash
CWD=$(pwd)
INIT=$(mktemp -d)

cd $INIT

mkdir -p {bin,dev,etc,lib,lib64,proc,root,sbin,sys,sdcard,squashfs,upper,overlay}
cp -a /dev/{null,console,tty,mmcblk0,ttyAMA0,ttyS0} ./dev/
cp $CWD/initscript ./init
chmod +x ./init
apt-get update
apt-get download busybox-static
dpkg -x *busybox-static*deb ./
rm *busybox-static*deb
./bin/busybox --install ./bin/

find . -print0 | cpio --null -ov --format=newc | gzip -9 > $CWD/enginfo.gz

cp $CWD/shellscript ./init
chmod +x ./init
find . -print0 | cpio --null -ov --format=newc | gzip -9 > $CWD/enginfo-shell.gz

cd $CWD