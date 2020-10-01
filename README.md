# Automation script of bootable SDCard for Zynq Board

This script automate the different operations to create a bootable SDCard for Xilinx Zynq development board. This was tested exclusively on a Digilent Zedboard.

## Requirements

* Linux system
* docker
* make
* sh

## Instructions

In order to juste compile the different files for the SD card, run ```./make_docker.sh```. If you then want to flash the SD card with the correct partitions, edit the ```MOUNT``` variable (line 5) in the Makefile then run ```make format.sdcard```.