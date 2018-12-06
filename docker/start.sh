#!/bin/bash

source /usr/local/rvm/environments/ruby-2.3.6@global

bundle install --deployment --without=test,development
sed -i -e 's/hostname: localhost/hostname: db.local/' -e 's/password:.*/password: password/' config/database.yml
rake db:setup
rake db:migrate
rake globodns:chroot:create
bundle exec unicorn_rails
