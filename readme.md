# Scripts for filling an sd-card for a raspberry pi with alpine linux and configuring it with:

* polling some bluetooth thermometers and writing to "the cloud"
* using a usb dongle for network
* functioning as a wifi access point
* diskless install, so the sd card is never written to
* unless you use lbu to commit changes
* installs updates on boot

## Usage examples

./generate-apkovl.sh hostname

./write-sd-card.sh /path/to/mounted/sd/card hostname.apkovl.tar.gz

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
