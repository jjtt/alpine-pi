#!/bin/bash

if [ $# -ne 7 ]
then
  echo "Usage: $0 <hostname> <domainname> <rootemail> <smtpserver> <sshpublickeyfile> <wwwsites> <staging/production>"
  exit 1
fi

#
# settings
HOSTNAME="$1"
DOMAINNAME="$2"
ROOTEMAIL="$3"
SMTPSERVER="$4"
SSHPUBLICKEYFILE="$5"
WWWSITES="$6"

# choose letsencrypt CA api url
CAURL="https://acme-staging-v02.api.letsencrypt.org/directory"
if [[ "$7" = "production" ]]
then
  CAURL="https://acme-v02.api.letsencrypt.org/directory"
fi

#
# work directory
TEMPD="$(mktemp -d)"

#
# ssh keys
mkdir -p "$TEMPD/etc/ssh"
ssh-keygen -f "$TEMPD/etc/ssh/ssh_host_rsa_key" -N '' -t rsa
ssh-keygen -f "$TEMPD/etc/ssh/ssh_host_dsa_key" -N '' -t dsa
ssh-keygen -f "$TEMPD/etc/ssh/ssh_host_ecdsa_key" -N '' -t ecdsa
ssh-keygen -f "$TEMPD/etc/ssh/ssh_host_ed25519_key" -N '' -t ed25519

#
# hosts
mkdir -p "$TEMPD/etc"
echo "127.0.0.1       $HOSTNAME.$DOMAINNAME $HOSTNAME localhost.localdomain localhost" > "$TEMPD/etc/hosts"
chmod 644 "$TEMPD/etc/hosts"

#
# hostname
mkdir -p "$TEMPD/etc"
echo "$HOSTNAME" > "$TEMPD/etc/hostname"
chmod 644 "$TEMPD/etc/hostname"

#
# dehydrated config
mkdir -p "$TEMPD/etc/dehydrated"
cat > "$TEMPD/etc/dehydrated/config" << EOF
CA="$CAURL"
WELLKNOWN="/var/www/localhost/htdocs/.well-known/acme-challenge/"
HOOK=/usr/local/bin/deploy_cert_hook
KEY_ALGO=prime256v1
EOF
chmod 644 "$TEMPD/etc/dehydrated/config"

#
# domains.txt
OTHERNAMES="$(ls "$WWWSITES" | grep -v ^$HOSTNAME.$DOMAINNAME\$ | paste -sd' ' -)"
mkdir -p "$TEMPD/etc/dehydrated"
echo "$HOSTNAME.$DOMAINNAME www.$HOSTNAME.$DOMAINNAME $OTHERNAMES > $HOSTNAME.$DOMAINNAME" > "$TEMPD/etc/dehydrated/domains.txt"
chmod 644 "$TEMPD/etc/dehydrated/domains.txt"

#
# ssmtp
mkdir -p "$TEMPD/etc/ssmtp"
cat > "$TEMPD/etc/ssmtp/ssmtp.conf" << EOF
root=$ROOTEMAIL
mailhub=$SMTPSERVER
hostname=$HOSTNAME.$DOMAINNAME
FromLineOverride=yes
EOF
chmod 644 "$TEMPD/etc/ssmtp/ssmtp.conf"

#
# sending server ip address hourly by email (in case server has dynamic ip)
mkdir -p "$TEMPD/etc/periodic/hourly"
cat > "$TEMPD/etc/periodic/hourly/osoite" << EOF
#!/bin/sh
(
  echo Subject: $HOSTNAME.$DOMAINNAME ip-osoite
  echo
  /bin/date -Iseconds
  /usr/bin/dig +short myip.opendns.com @resolver1.opendns.com
  /sbin/ip addr show dev eth0 |/bin/grep "inet "
) | /usr/sbin/ssmtp $ROOTEMAIL
EOF
chmod 755 "$TEMPD/etc/periodic/hourly/osoite"

#
# lighttpd.conf
mkdir -p "$TEMPD/etc/lighttpd"
cat > "$TEMPD/etc/lighttpd/lighttpd.conf" << EOF
var.basedir  = "/var/www/localhost"
var.logdir   = "/var/log/lighttpd"
var.statedir = "/var/lib/lighttpd"
server.modules = (
    "mod_redirect",
    "mod_access",
    "mod_openssl",
    "mod_accesslog",
    "mod_simple_vhost"
)
include "mime-types.conf"
server.username      = "lighttpd"
server.groupname     = "lighttpd"
server.document-root = var.basedir + "/htdocs"
server.pid-file      = "/run/lighttpd.pid"
server.errorlog      = var.logdir  + "/error.log"
server.indexfiles    = ("index.php", "index.html", "index.htm", "default.htm")
server.follow-symlink = "enable"
static-file.exclude-extensions = (".php", ".pl", ".cgi", ".fcgi")
accesslog.filename   = var.logdir + "/access.log"
url.access-deny = ("~", ".inc")
\$HTTP["url"] !~ "^/\.well-known/" {
  simple-vhost.server-root         = "/var/www"
  simple-vhost.document-root       = "htdocs"
  simple-vhost.default-host        = "$HOSTNAME.$DOMAINNAME"
}
include_shell "/etc/lighttpd/ssl.sh /etc/dehydrated/certs/$HOSTNAME.$DOMAINNAME"
\$HTTP["host"] == "www.$HOSTNAME.$DOMAINNAME" {
  url.redirect = ( "^/(.*)" => "http://$HOSTNAME.$DOMAINNAME/\$1" )
}
EOF
chmod 644 "$TEMPD/etc/lighttpd/lighttpd.conf"
cat > "$TEMPD/etc/lighttpd/ssl.conf" << EOF
\$SERVER["socket"] == ":443" {
  ssl.engine    = "enable"
  ssl.pemfile   = "/etc/dehydrated/certs/$HOSTNAME.$DOMAINNAME/combined.pem"
  ssl.ca-file   = "/etc/dehydrated/certs/$HOSTNAME.$DOMAINNAME/chain.pem"
}
\$HTTP["scheme"] == "http" {
  \$HTTP["host"] =~ ".*" {
    url.redirect = (".*" => "https://%0\$0")
  }
}
EOF
chmod 644 "$TEMPD/etc/lighttpd/ssl.conf"

#
# MAILTO in crontab
mkdir -p "$TEMPD/etc/crontabs"
cat > "$TEMPD/etc/crontabs/root" << EOF
MAILTO=$ROOTEMAIL
# do daily/weekly/monthly maintenance
# min   hour    day     month   weekday command
*/15    *       *       *       *       run-parts /etc/periodic/15min
0       *       *       *       *       run-parts /etc/periodic/hourly
0       2       *       *       *       run-parts /etc/periodic/daily
0       3       *       *       6       run-parts /etc/periodic/weekly
0       5       1       *       *       run-parts /etc/periodic/monthly
EOF
chmod 600 "$TEMPD/etc/crontabs/root"

#
# motd - we do not welcome strangers here
mkdir -p "$TEMPD/etc"
cat > "$TEMPD/etc/motd" << EOF
$HOSTNAME.$DOMAINNAME

You are not allowed to be here.

EOF
chmod 644 "$TEMPD/etc/motd"

#
# authorized_keys
mkdir -p "$TEMPD/root/.ssh"
chmod 700 "$TEMPD/root/.ssh"
SSHPUBLICKEYFILE="$5"
cat "$SSHPUBLICKEYFILE" > "$TEMPD/root/.ssh/authorized_keys"
chmod 600 "$TEMPD/root/.ssh/authorized_keys"

#
# www sites
mkdir -p "$TEMPD/var/www"
cp -r "$WWWSITES/"* "$TEMPD/var/www"

#
# create apkovl for configured hostname
tar -cf "$HOSTNAME.apkovl.tar" -C "initial-shadow" --owner=root:0 --group=shadow:42 etc
tar -rf "$HOSTNAME.apkovl.tar" -C "initial" --owner=root:0 --group=root:0 etc root usr var
tar -rf "$HOSTNAME.apkovl.tar" -C "$TEMPD" --owner=root:0 --group=root:0 etc root var
gzip "$HOSTNAME.apkovl.tar"

#
# cleanup
#rm -Rf "$TEMPD"
echo $TEMPD
