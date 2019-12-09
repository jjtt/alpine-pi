#!/bin/bash

if [ $# -ne 2 ]
then
  echo "Usage: $0 <hostname> <url>"
  exit 1
fi

#
# settings
HOSTNAME="$1"
URL="$2"

#
# work directory
TEMPD="$(mktemp -d)"

#
# hosts
mkdir -p "$TEMPD/etc"
echo "127.0.0.1       $HOSTNAMEAINNAME $HOSTNAME localhost.localdomain localhost" > "$TEMPD/etc/hosts"
chmod 644 "$TEMPD/etc/hosts"

#
# hostname
mkdir -p "$TEMPD/etc"
echo "$HOSTNAME" > "$TEMPD/etc/hostname"
chmod 644 "$TEMPD/etc/hostname"

#
# motd - we do not welcome strangers here
mkdir -p "$TEMPD/etc"
cat > "$TEMPD/etc/motd" << EOF
$HOSTNAME

You are not allowed to be here.

EOF
chmod 644 "$TEMPD/etc/motd"

#
# add chromium to world
mkdir -p "$TEMPD/etc/apk"
cat > "$TEMPD/etc/apk/world" << EOF
alpine-base
chrony
openssl
chromium
EOF
chmod 644 "$TEMPD/etc/apk/world"

#
# startx
mkdir -p "$TEMPD/root"
cat > "$TEMPD/root/.profile" << EOF
#!/bin/sh
exec startx
EOF
chmod 644 "$TEMPD/root/.profile"

#
# create apkovl for configured hostname
cp initial.apkovl.tar "$HOSTNAME.apkovl.tar"
tar -rf "$HOSTNAME.apkovl.tar" -C "$TEMPD" --owner=root:0 --group=root:0 etc root
gzip "$HOSTNAME.apkovl.tar"

#
# cleanup
rm -Rf "$TEMPD"
