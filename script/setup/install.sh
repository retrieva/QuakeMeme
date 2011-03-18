#!/bin/bash

# installing packages
apt-get update
apt-get install libxslt1-dev libxml2-dev mysql-server libmysqlclient15-dev memcached
gem install rails -v=2.3.5
gem install hpricot
gem install json
gem install mechanize
gem install nokogiri
gem install unicorn -v=1.1.2
gem install mysql -v=2.8.1

# install config files
mkdir -p /etc/unicorn/
cp -f unicorn.conf /etc/unicorn/
cp -f rails_env.sh /etc/profile.d/
cp -f unicorn /etc/init.d/unicorn
chmod +x /etc/init.d/unicorn
