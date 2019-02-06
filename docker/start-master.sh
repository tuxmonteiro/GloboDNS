#!/bin/bash

rndc-confgen -s $(host globodns.master | head -1 | awk '{ print $4 }') | grep -v '^#' | tee /etc/named/rndc.conf
echo "controls { inet $(host globodns.master | head -1 | awk '{ print $4 }') allow { $(host globodns.local | head -1 | awk '{ print $4 }'); } keys { ""rndc-key""; };};" >> /etc/named/named.conf
echo "key ""rndc-key"" { algorithm ""hmac-md5""; $(grep secret /etc/named/rndc.conf) };" >> /etc/named/named.conf

/usr/sbin/named -u named -c /etc/named.conf
/usr/sbin/sshd -D
