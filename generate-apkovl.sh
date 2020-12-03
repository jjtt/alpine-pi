#!/bin/bash
if [ $# -ne 1 ]
then
  echo "Usage: $0 <hostname>"
  exit 1
fi

#
# settings
HOSTNAME="$1"

#
# work directory
TEMPD="$(mktemp -d)"

#
# apk arch
mkdir -p "$TEMPD/etc/apk"
echo "armhf" > "$TEMPD/etc/apk/arch"
chmod 644 "$TEMPD/etc/apk/arch"

#
# hosts
mkdir -p "$TEMPD/etc"
echo "127.0.0.1       $HOSTNAME localhost.localdomain localhost" > "$TEMPD/etc/hosts"
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
# enable community repository
mkdir -p "$TEMPD/etc/apk"
cat > "$TEMPD/etc/apk/repositories" << EOF
http://alpine.mirror.far.fi/v3.12/main
http://alpine.mirror.far.fi/v3.12/community
EOF
chmod 644 "$TEMPD/etc/apk/repositories"

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
# add packages to to world
mkdir -p "$TEMPD/etc/apk"
cat > "$TEMPD/etc/apk/world" << EOF
alpine-base
python3
py3-pip
EOF
chmod 644 "$TEMPD/etc/apk/world"

#
# create apkovl for configured hostname
cp initial.apkovl.tar "$HOSTNAME.apkovl.tar"
tar -rf "$HOSTNAME.apkovl.tar" -C "$TEMPD" --owner=root:0 --group=root:0 etc
gzip "$HOSTNAME.apkovl.tar"

#
# cleanup
rm -Rf "$TEMPD"
