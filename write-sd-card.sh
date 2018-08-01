#!/bin/bash

if [ $# -ne 2 ]
then
  echo "Usage: $0 <path_to_mounted_sd_card_with_fat32> <apkovl_file>"
  exit 1
fi

SDCARD="$1"
APKOVL="$2"
ALPINE=http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/armhf/alpine-rpi-3.8.0-armhf.tar.gz

# download if alpine not downloaded already
if [ ! -f ${ALPINE##*/} ]
then
  wget $ALPINE
fi

tar -xzvf ${ALPINE##*/} -C "$SDCARD"

cp -v usercfg.txt "$SDCARD"

cp -v "$APKOVL" "$SDCARD"

mkdir -v "$SDCARD/cache"
