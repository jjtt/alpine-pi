# Scripts for filling an sd-card for a raspberry pi with alpine linux and configuring it with:

* a Let's encrypt certificate using dehydrated.io
* lighttpd
* openssh with public key authentication for root
* diskless install, so the sd card is never written to
* unless you use lbu to commit changes
* installs updates on boot
* sends own ip address as email just in case it changes

## Usage examples

./generate-apkovl.sh hostname domain.com.invalid email.address@for.various.notifications.invalid smtp.server.invalid path/to/ssh/keyfile.pub www/ staging

./write-sd-card.sh /path/to/mounted/cd/card hostname.apkovl.tar.gz

### web sites

The web sites to serve must be placed in a single directory given as a parameter
to generate-apkovl.sh. Each web site must be placed in a separate sub directory:

* domain1.com.invalid
  * htdocs
    * index.html
* domain2.fi.invalid
  * htdocs
    * index.html

One of the web sites should probably be the hostname.domain.com.invalid given as
a parameter. www.hostname.domain.com.invalid is redirected automatically.

## Dependencies

Lots.

* wget
* openssh
* bash
* tar
* gzip
* ...

## Missing features

* configurable timezone
* actual content for the website
* static ip support
* dynamic dns support
