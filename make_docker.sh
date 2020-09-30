#!/bin/sh
docker build -t zynq-boot .
CONTAINER_ID=$(docker create -ti --name zynq zynq-boot /bin/sh)
docker start $CONTAINER_ID
docker exec $CONTAINER_ID make all
docker cp $CONTAINER_ID:/usr/app/sdcard ./
docker stop zynq