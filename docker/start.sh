#!/bin/bash

service named start

source /usr/local/rvm/environments/ruby-${RUBY_ENV}@global

sed -i -e 's/host:.*/host: globodnsdb.local/g' -e 's/password:.*/password: password/' config/database.yml
bundle exec rake db:setup
bundle exec rake db:migrate
bundle exec rake db:seed
bundle exec rake globodns:chroot:create
bundle exec ruby script/importer --force --master-chroot-dir="$BIND_CHROOT_DIR"
bundle exec unicorn_rails
