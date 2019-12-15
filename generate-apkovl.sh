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
# enable community repository
mkdir -p "$TEMPD/etc/apk"
cat > "$TEMPD/etc/apk/repositories" << EOF
http://alpine.mirror.far.fi/v3.10/main
http://alpine.mirror.far.fi/v3.10/community
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
# add xorg and chromium to world
mkdir -p "$TEMPD/etc/apk"
cat > "$TEMPD/etc/apk/world" << EOF
alpine-base
chrony
openssl
xorg-server
xf86-video-vesa
xf86-input-evdev
xf86-input-mouse
xf86-input-keyboard
udev
mesa-dri-vc4
mesa-egl
xf86-video-fbdev
dbus
setxkbmap
kbd
xrandr
xset
chromium
EOF
chmod 644 "$TEMPD/etc/apk/world"

#
# configure chromium policies
mkdir -p "$TEMPD/etc/chromium/policies/managed"
cat > "$TEMPD/etc/chromium/policies/managed/curtom_policies.json" << EOF
{
  "CommandLineFlagSecurityWarningsEnabled": false
}
EOF
chmod 644 "$TEMPD/etc/chromium/policies/managed/curtom_policies.json"

#
# inittab to log in root automatically
mkdir -p "$TEMPD/etc"
cat > "$TEMPD/etc/inittab" << EOF
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default
tty1::respawn:/bin/login -f root
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/openrc shutdown
EOF
chmod 644 "$TEMPD/etc/inittab"

#
# startx
mkdir -p "$TEMPD/root"
cat > "$TEMPD/root/.profile" << EOF
#!/bin/sh
exec startx -- -nocursor
EOF
chmod 644 "$TEMPD/root/.profile"

#
# xinitrc
mkdir -p "$TEMPD/root"
cat > "$TEMPD/root/.xinitrc" << EOF
#!/bin/sh

# turn off screensaver
xset -dpms
xset s off
xset s noblank

# read url
url="\$(cat /media/mmcblk0p1/url.txt)"

# screen size
width="1920"
height="1080"

exec chromium-browser \$url --window-size=\$width,\$height --window-position=0,0 --kiosk --no-sandbox --full-screen --incognito --noerrdialogs --disable-translate --no-first-run --fast --fast-start --ignore-gpu-blacklist --disable-quic --enable-fast-unload --enable-tcp-fast-open ---enable-native-gpu-memory-buffers --enable-gpu-rasterization --enable-zero-copy --disable-features=TranslateUI --disk-cache-dir=/tmp
EOF
chmod 644 "$TEMPD/root/.xinitrc"

#
# create apkovl for configured hostname
cp initial.apkovl.tar "$HOSTNAME.apkovl.tar"
tar -rf "$HOSTNAME.apkovl.tar" -C "$TEMPD" --owner=root:0 --group=root:0 etc root
gzip "$HOSTNAME.apkovl.tar"

#
# cleanup
rm -Rf "$TEMPD"
