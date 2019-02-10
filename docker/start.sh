#!/bin/bash

sudo /usr/libexec/setup-named-chroot.sh /var/named/chroot on
source /usr/local/rvm/environments/ruby-${RUBY_ENV}@global

while ! nc --recv-only -i1 127.0.0.1 3306 2> /dev/null| strings | grep 5.6 > /dev/null 2>&1; do
sleep 1
echo "wait mysql"
done

bundle exec rake db:setup
bundle exec rake db:migrate
bundle exec rake db:seed
bundle exec rake globodns:chroot:create
bundle exec ruby script/importer --force --remote
#bundle exec unicorn_rails

sleep 999999
