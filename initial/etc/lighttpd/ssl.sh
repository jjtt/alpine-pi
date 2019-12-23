#!/bin/sh
if [ -d "$1" ]
then
  cat /etc/lighttpd/ssl.conf
fi
