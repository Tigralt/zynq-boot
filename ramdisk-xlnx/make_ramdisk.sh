dd if=/dev/zero of=arm_ramdisk.image bs=1024 count=16384
mke2fs -F arm_ramdisk.image -L "ramdisk" -b 1024 -m 0
tune2fs arm_ramdisk.image -i 0
chmod a+rwx arm_ramdisk.image
