#!/bin/bash
# Copyright (c) Intel Corporation.
# Licensed under the MIT License.

set -x

#. /lib/dracut-lib.sh

info "mount tmpfs for root"
mount -t tmpfs -o size=1G tmpfs $NEWROOT

cd $NEWROOT
#mkdir -p boot dev etc home mnt media proc sys run tmp usr usr/bin usr/sbin usr/lib var
#chown root:root boot dev etc home mnt media proc sys run tmp usr usr/bin usr/sbin usr/lib var
#chmod 0700 boot
#chmod 0755 dev etc home mnt media proc sys run tmp usr usr/bin usr/sbin usr/lib var
#
#info "copying rootfs files"
#ln -s usr/bin bin
#ln -s usr/sbin sbin
#ln -s usr/lib lib
#ln -s usr/lib lib64
#chown root:root bin sbin lib lib64
#chmod 0777 bin sbin lib lib64
#
#cp -a /dev/* dev/
#cp -R /usr/sbin/* usr/sbin/
#cp -R /usr/bin/* usr/bin/
#cp -R /usr/lib/* usr/lib/
#cp -R /var/lib var/
#cp -R /etc/* etc/
#ls /sysroot
#cp etc/edge-release etc/os-release 
#cat etc/os-release

if [[ -f /rootfs.tar.gz ]]; then
  info "extract rootfs.tar.gz to $NEWROOT"
  tar -xvf /rootfs.tar.gz -C $NEWROOT
else
  warn "no rootfs.tar.gz found"
  die
fi

info "rootfs on tmpfs complete"
