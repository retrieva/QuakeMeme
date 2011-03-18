#!/bin/bash

# installing packages
apt-get update
apt-get install libxslt1-dev libxml2-dev mysql-server libmysqlclient15-dev memcached git-core emacs22 subversion screen nginx

# gem install
gem install rails -v=2.3.5
gem install hpricot
gem install json
gem install mechanize
gem install nokogiri
gem install unicorn -v=1.1.2
gem install mysql -v=2.8.1

# nginx
cp -f default /etc/nginx/sites-enabled/default
cp -f nginx.conf /etc/nginx/

# rubygem install
wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.2.tgz
tar vzxf rubygems-1.3.2.tgz
cd rubygems-1.3.2
rake install
cd ..

# install config files
mkdir -p /etc/unicorn/
cp -f unicorn.conf /etc/unicorn/
cp -f rails_env.sh /etc/profile.d/
cp -f unicorn /etc/init.d/unicorn
chmod +x /etc/init.d/unicorn

# git clone
cd /root/
git clone git://github.com/pfi/QuakeMeme.git
mkdir -p /mnt/log/rails/
ln -s /mnt/log/rails/ /root/QuakeMeme/log
