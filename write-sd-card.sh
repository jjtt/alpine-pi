#!/bin/bash

if [ $# -ne 3 ]
then
  echo "Usage: $0 <path_to_mounted_sd_card_with_fat32> <apkovl_file> <url>"
  exit 1
fi

SDCARD="$1"
APKOVL="$2"
URL="$3"
ALPINE=http://dl-cdn.alpinelinux.org/alpine/v3.10/releases/armv7/alpine-rpi-3.10.3-armv7.tar.gz

# download if alpine not downloaded already
if [ ! -f ${ALPINE##*/} ]
then
  wget $ALPINE
fi

tar -xzvf ${ALPINE##*/} -C "$SDCARD"

cp -v usercfg.txt "$SDCARD"

cp -v "$APKOVL" "$SDCARD"

mkdir -v "$SDCARD/cache"

echo -n "$URL" > "$SDCARD/url.txt"
