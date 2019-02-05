#!/bin/bash

systemctl stop named || true
systemctl disable named || true
/usr/libexec/setup-named-chroot.sh /var/named/chroot on
systemctl start named-chroot

source /usr/local/rvm/environments/ruby-${RUBY_ENV}@global

sed -i -e 's/host:.*/host: globodnsdb.local/g' -e 's/password:.*/password: password/' config/database.yml

while ! echo >/dev/tcp/globodnsdb.local/3306; do
sleep 1
echo "wait globodnsdb.local:3306"
done

bundle exec rake db:setup
bundle exec rake db:migrate
bundle exec rake db:seed
bundle exec rake globodns:chroot:create
bundle exec ruby script/importer --force --master-chroot-dir="$BIND_CHROOT_DIR"
bundle exec unicorn_rails
