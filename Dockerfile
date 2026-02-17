FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt update && \
    apt install -y \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
    git gnupg gperf imagemagick lib32z1-dev liblz4-tool \
    libncurses5-dev libssl-dev libxml2-utils lzop \
    pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev \
    openjdk-11-jdk python3 sudo

RUN mkdir -p /opt/android
WORKDIR /opt/android

ENV USE_CCACHE=1
ENV CCACHE_DIR=/opt/android/.ccache

CMD ["bash"]
