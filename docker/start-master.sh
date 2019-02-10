#!/bin/bash

/usr/libexec/setup-named-chroot.sh /var/named/chroot on
rndc-confgen -s 127.0.0.1 | grep -v '^#' | tee /etc/named/rndc.conf
echo "controls { inet 127.0.0.1 allow { 127.0.0.1; } keys { ""rndc-key""; };};" >> /etc/named/named.conf
echo "key ""rndc-key"" { algorithm ""hmac-md5""; $(grep secret /etc/named/rndc.conf) };" >> /etc/named/named.conf

/usr/sbin/named -u named -c /etc/named.conf -t /var/named/chroot
/usr/sbin/sshd -D
