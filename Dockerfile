FROM ubuntu:bionic

COPY / /usr/app
WORKDIR /usr/app

RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install -y \
    curl \
    bc \
    git \
    unzip \
    build-essential \
    libssl-dev \
    libelf-dev \
    libpcre3-dev \
    zlib1g-dev \
    libncurses5-dev \
    lzop \
    gcc-6-arm-linux-gnueabi \
    binutils-arm-linux-gnueabihf
RUN ln -s /usr/bin/arm-linux-gnueabi-gcc-6 /usr/bin/arm-linux-gnueabi-gcc