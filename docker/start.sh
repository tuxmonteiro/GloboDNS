#!/bin/bash

source /usr/local/rvm/environments/ruby-${RUBY_ENV}@global

sed -i -e 's/hostname: localhost/hostname: db.local/' -e 's/password:.*/password: password/' config/database.yml
bundle exec rake db:setup
bundle exec rake db:migrate
bundle exec rake globodns:chroot:create
bundle exec unicorn_rails
