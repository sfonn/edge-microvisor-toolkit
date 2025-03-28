#!/bin/bash

# Copyright (c) Intel Corporation.
# Licensed under the MIT License.

# Failure can be ignored.
set -e
set -x

# regen initramfs for tink
echo "force final regen initramfs"

# gen a bigger initramfs
#dracut --install "/bin /sbin /usr /var /sys /srv /dev /run /etc /lib /lib64 /mnt /opt /proc" \
#       --nohardlink -v --no-hostonly --nofscks --force --regenerate-all \
#       --add "base kernel-modules rootfs-block"

#dracut -v --no-hostonly --nofscks --force --regenerate-all --add "dmsquash-live"

#ls /sys
#ls /proc
#mksquashfs --help
# make squashfs for minimal os
#mksquashfs /usr /etc /squashfs.img \
#           -progress -info -no-recovery \
#           -noappend -wildcards -exit-on-error \
#           -p '/bin s 0777 0 0 /usr/bin' \
#           -p '/sbin s 0777 0 0 /usr/sbin' \
#           -p '/lib s 0777 0 0 /usr/lib' \
#           -p '/lib64 s 0777 0 0 /usr/lib' \
#           -p '/dev d 0755 0 0' \
#           -p '/mnt d 0755 0 0' \
#           -p '/opt d 0755 0 0' \
#           -p '/proc d 0755 0 0' \
#           -p '/run d 0755 0 0' \
#           -p '/sys d 0755 0 0' \
#           -p '/srv d 0755 0 0' \
#           -p '/tmp d 0755 0 0' \
#           -e log include src share man

           
#echo $(ls -l /squashfs.img)
# dracut defaults to look for /LiveOS/squashfs.img

ramfs=$(find /boot -type f -name initramfs*img -printf '%f\n')
# unzip initramfs
mkdir /tmp/initramfs
cd /tmp/initramfs
echo "inside $(pwd)"
echo "unziping initial initramfs for repack"
gunzip -c -k /boot/$ramfs | cpio -idmv --no-absolute-filenames
echo "free space $(df -h)"

mkdir /tmp/rootfs
cd /tmp/rootfs
echo "inside $(pwd)"
echo "free space $(df -h)"
mkdir -p boot dev etc home mnt media proc sys run tmp usr usr/bin usr/sbin usr/lib var
chown root:root boot dev etc home mnt media proc sys run tmp usr usr/bin usr/sbin usr/lib var
chmod 0700 boot
chmod 0755 dev etc home mnt media proc sys run tmp usr usr/bin usr/sbin usr/lib var
echo "copy initial initramfs for rootfs"
cp -a /tmp/initramfs/dev/* dev/
ln -s usr/bin bin
ln -s usr/sbin sbin
ln -s usr/lib lib
ln -s usr/lib lib64
chown root:root bin sbin lib lib64
chmod 0777 bin sbin lib lib64
echo "after initramfs copy $(ls -l .)"
echo "after initramfs copy $(du -h /tmp/rootfs)"
echo "copying rootfs files"
cp -R /usr/sbin/* usr/sbin/ 
cp -R /usr/bin/* usr/bin/ 
cp -R /usr/lib/* usr/lib/ 
cp -R /var/lib var/ 
cp -R /etc/* etc/
# override boot device command line
echo "fstab contents $(cat etc/fstab)"
echo 'tmpfs   /   tmpfs   defaults,size=1G   0   0' > etc/fstab
#echo "" > etc/fstab
echo "fstab contents after edit $(cat etc/fstab)"
# simple setup for console
echo 'LANG=en_US.UTF-8' > etc/locale.conf
echo 'keymap=us' > etc/vconsole.conf
mkdir -p usr/share/terminfo/v
cp -R /usr/share/terminfo/v/vt220 usr/share/terminfo/v/
echo "console setup $(cat etc/locale.conf etc/vconsole.conf)"
echo "after copy $(du -h /tmp/rootfs)"
echo "free space $(df -h)"
tar cf - -C . . | gzip -9 > /rootfs.tar.gz
cd -
echo $(ls -l /rootfs.tar.gz)
rm -rf /tmp/rootfs


#mkdir LiveOS
#mv /squashfs.img LiveOS/squashfs.img

cd /tmp/initramfs
echo "inside $(pwd)"
echo "after copy $(du -h /tmp/initramfs)"
echo "check cmdline.d $(ls etc/cmdline.d)"
echo "check cmdline.d contents $(cat etc/cmdline.d/95root-dev.conf)"
#echo 'root=tmpfs rootfstype=tmpfs'  > etc/cmdline.d/95root-dev.conf
#echo 'root= rootfstype=auto'  > etc/cmdline.d/95root-dev.conf
echo 'root=tmpfs rootflags=size=1G,mode=0755' > etc/cmdline.d/95root-dev.conf
echo "check cmdline.d contents after edit $(cat etc/cmdline.d/95root-dev.conf)"
echo "before rm devexist* $(ls -al var/lib/dracut/hooks/initqueue/finished/)"
rm -f var/lib/dracut/hooks/initqueue/finished/devexists*
echo "after rm devexist* $(ls -al var/lib/dracut/hooks/initqueue/finished/)"
echo "before rm wants $(ls -al etc/systemd/system/initrd.target.wants/)"
rm -rf etc/systemd/system/initrd.target.wants/dev-disk-b*
echo "after rm wants $(ls etc/systemd/system/initrd.target.wants/)"
echo "before rm disk service $(ls -al etc/systemd/system/dev-disk-b*)"
rm -rf etc/systemd/system/dev-disk-b*
echo "after rm disk service $(ls -al etc/systemd/system/)"
echo "$(find . -iname dev-disk*)"
# copy tar required for uncompressing rootfs archive
echo "before copy tar $(find . -iname tar)"
cp /usr/bin/tar usr/bin
echo "after copy tar $(find . -iname tar)"
mv /rootfs.tar.gz /tmp/initramfs/
find . | cpio -o -H newc | gzip > /boot/$ramfs
echo $(ls -l ./rootfs.tar.gz)
cd -

echo $(ls -l /boot/$ramfs)
rm -rf /tmp/initramfs

# for testing ramfs
#cp /boot/initramfs-*.img /boot/vmlinuz-* /mnt/cdrom/

sed -i "s|GRUB_TIMEOUT=0|GRUB_TIMEOUT=10|g" "/etc/default/grub"
sed -i "s|GRUB_CMDLINE_LINUX=|#GRUB_CMDLINE_LINUX=|g" "/etc/default/grub"
sed -i "s|GRUB_DISABLE_SUBMENU=y|GRUB_DISABLE_SUBMENU=n|g" "/etc/default/grub"
tee -a /etc/grub.d/40_custom <<EOF
menuentry 'Boot to Initramfs Shell' {
    load_video
    insmod gzio
    insmod part_gpt
    insmod ext2
    set root='(hd0,gpt2)'
    echo        'Loading Linux emt3 ...'
    linux       /boot/vmlinuz-6.12.20-1.emt3 root=tmpfs rootflags=size=1G,mode=0755 rd.skipfsck noresume loglevel=7 rd.shell rd.debug systemd.log_level=debug systemd.log_target=kmsg
    echo        'Loading initial ramdisk ...'
    initrd      /boot/initramfs-6.12.20-1.emt3.img
}
EOF
/usr/sbin/grub2-mkconfig > /boot/grub2/grub.cfg || :

