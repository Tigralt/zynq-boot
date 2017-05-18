# General config
SDCARD_DIR=sdcard

# sdcard config
MOUNT?=sdb
MOUNTED=`ls /dev | grep -c $(MOUNT)`

# Compile config
CROSS_COMPILE?=arm-linux-gnueabi-

# Board config
BOARD?=zed
UIMAGE_LOADADDR?=0x8000

# U-BOOT config
U_BOOT_DIR=u-boot-xlnx
U_BOOT_REPO=https://github.com/Xilinx/$(U_BOOT_DIR)
U_BOOT_CONFIG=zynq_$(BOARD)_config

# uImage config
LINUX_DIR=linux-xlnx
LINUX_REPO=https://github.com/Xilinx/$(LINUX_DIR)
LINUX_CROSS_COMPILE=arm-linux-gnueabi-
LINUX_DEVICE_TREE=arch/arm/boot/dts/zynq-$(BOARD).dts

# FSBL config
FSBL_DIR=fsbl-xlnx

# Ramdisk config
RAMDISK_DIR=ramdisk-xlnx

# BOOT.bin config
BOOTGEN:=$(shell command -v bootgen 2> /dev/null)


all: u-boot linux fsbl ramdisk boot.bin
	@echo "Work is done! You can now copy files from '$(SDCARD_DIR)'/ to your SD card or use the make option to do so."

u-boot:
	@[ -d "$(SDCARD_DIR)" ] || mkdir $(SDCARD_DIR)
	@[ -d "$(U_BOOT_DIR)" ] || echo "Downloading u-boot repository from $(U_BOOT_REPO)"
	@[ -d "$(U_BOOT_DIR)" ] || git clone $(U_BOOT_REPO)
	make -C $(U_BOOT_DIR) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) zynq_$(BOARD)_config
	make -C $(U_BOOT_DIR) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)
	@cp $(U_BOOT_DIR)/u-boot $(SDCARD_DIR)/u-boot.elf

linux:
	@[ -d "$(SDCARD_DIR)" ] || mkdir $(SDCARD_DIR)
	@[ -d "$(U_BOOT_DIR)" ] || make u-boot
	@[ -d "$(LINUX_DIR)" ] || echo "Downloading linux repository from $(LINUX_REPO)"
	@[ -d "$(LINUX_DIR)" ] || git clone $(LINUX_REPO);
	@cp .config $(LINUX_DIR)
	make -C $(LINUX_DIR) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) UIMAGE_LOADADDR=$(UIMAGE_LOADADDR) PATH=$(PATH):$(shell pwd)/$(U_BOOT_DIR)/tools/ uImage
	@echo "Make board devicetree"
	@sed -i 's/\#include/\/include\//g' $(LINUX_DIR)/arch/arm/boot/dts/zynq-$(BOARD).dts
	@$(LINUX_DIR)/scripts/dtc/dtc -I dts -O dtb -o $(SDCARD_DIR)/devicetree.dtb $(LINUX_DIR)/arch/arm/boot/dts/zynq-$(BOARD).dts
	@cp $(LINUX_DIR)/arch/arm/boot/uImage $(SDCARD_DIR)/
	@cp $(SDCARD_DIR)/uImage $(SDCARD_DIR)/uImage.bin

fsbl:
	@if ! [ -d "$(SDCARD_DIR)" ]; then mkdir $(SDCARD_DIR); fi
	@echo "Copy board FSBL"
	@cp $(FSBL_DIR)/zynq-$(BOARD).elf $(SDCARD_DIR)/fsbl.elf

ramdisk:
	@if ! [ -d "$(SDCARD_DIR)" ]; then mkdir $(SDCARD_DIR); fi
	@echo "Make ramdisk image"
	@$(U_BOOT_DIR)/tools/mkimage -A arm -T ramdisk -C gzip -d $(RAMDISK_DIR)/arm_ramdisk.image.gz $(SDCARD_DIR)/uramdisk.image.gz

boot.bin:
	@echo "all: { [bootloader]$(SDCARD_DIR)/fsbl.elf $(SDCARD_DIR)/u-boot.elf [load=0x2000000]$(SDCARD_DIR)/devicetree.dtb [load=0x4000000]$(SDCARD_DIR)/uramdisk.image.gz [load=0x2080000]$(SDCARD_DIR)/uImage.bin }" > $(SDCARD_DIR)/boot.bif
	@bootgen -image $(SDCARD_DIR)/boot.bif -o i $(SDCARD_DIR)/BOOT.bin -w
	@rm $(SDCARD_DIR)/*.elf $(SDCARD_DIR)/uImage.bin $(SDCARD_DIR)/*.bif

clean:
	@if [ -d "$(U_BOOT_DIR)" ]; then rm -rf $(U_BOOT_DIR); fi
	@if [ -d "$(LINUX_DIR)" ]; then rm -rf $(LINUX_DIR); fi
	@if [ -d "$(SDCARD_DIR)" ]; then rm -rf $(SDCARD_DIR); fi

format.sdcard:
	@[ $(MOUNTED) -gt 0 ] || (echo "SD card mount point '/dev/$(MOUNT)' not found. Is the sd card mounted?" && exit -1)
	@echo "Root authorization is required in order to format sd card."
	@echo "Verify that the sd card is not mounted, the format will fail otherwise!"
	@sudo dd if=/dev/zero of=/dev/$(MOUNT) bs=1024 count=1
	@echo -e "x\nh\n255\ns\n63\nr\nn\np\n1\n2048\n+200M\nn\np\n2\n\n\na\n1\nt\n1\nc\nt\n2\n83\nw\n" | sudo fdisk /dev/$(MOUNT)
	@sudo mkfs.vfat -F 32 -n BOOT /dev/$(MOUNT)1
	@sudo mkfs.ext4 -L root /dev/$(MOUNT)2
	@echo "SD card format successful! You can know copy files from '$(SDCARD_DIR)/' to SD card."

make.sdcard:
	@read -p "Where is mounted the SD card?: " sdcard_mount; rm $$sdcard_mount/*; cp $(SDCARD_DIR)/* $$sdcard_mount/

all.sdcard: format.sdcard make.sdcard

help: 
	@echo "Usage: make [TOOL] [BOARD=] [CROSS_COMPILE=] [MOUNT=]"
	@echo "    BOARD:         zed (default: zed)"
	@echo "    CROSS_COMPILE: The cross compiler (default: arm-linux-gnueabi-)"
	@echo "    MOUNT:         The sd card mount point (default: /dev/sdb)"
	@echo "    TOOL:"
	@echo "        all (default): Make u-boot, linux, fsbl, ramdisk and boot.bin"
	@echo "        u-boot:   Make the u-boot.elf file"
	@echo "        linux:    Make the linux uImage"
	@echo "        fsbl:     Select the correct FSBL"
	@echo "        ramdisk:  Make the ramdisk image"
	@echo "        boot.bin: Make the BOOT.bin file"
	@echo "        format.sdcard: Format the sdcard for the board"
	@echo "        make.sdcard:   Copy all files to SD card"
	@echo "        all.sdcard:    Format SD card then copy all files on it"
