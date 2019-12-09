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
# apk arch
mkdir -p "$TEMPD/etc/apk"
echo "armv7" > "$TEMPD/etc/apk/arch"
chmod 644 "$TEMPD/etc/apk/arch"

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
# enable local service
mkdir -p "$TEMPD/etc/conf.d"
cat > "$TEMPD/etc/conf.d/local" << EOF
rc_verbose=yes
EOF
chmod 644 "$TEMPD/etc/conf.d/local"
mkdir -p "$TEMPD/etc/runlevels/default"
ln -s /etc/init.d/local "$TEMPD/etc/runlevels/default/local"

#
# install and update on boot
mkdir -p "$TEMPD/etc/local.d"
cat > "$TEMPD/etc/local.d/00apk-update-upgrade.start" << EOF
#!/bin/sh
echo "apk update & upgrade"

/sbin/apk update

OUTPUT=\$(/sbin/apk upgrade)
echo "\$OUTPUT"
echo "\$OUTPUT" | grep -E "Installing|Upgrading" > /dev/null
if [ \$? -eq 0 ]
then
  echo "Something was installed or upgraded - rebooting"
  /sbin/reboot
fi

echo "apk update & upgrade - done"
EOF
chmod 755 "$TEMPD/etc/local.d/00apk-update-upgrade.start"

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
