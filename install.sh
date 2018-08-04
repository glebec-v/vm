#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# NGINX
echo "installing nginx"
if [[ ! -f /etc/nginx ]]; then
    echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" > /etc/apt/sources.list.d/nginx.list
    echo "deb-src http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list.d/nginx.list
    curl http://nginx.org/keys/nginx_signing.key | apt-key add -
    apt-get update && apt-get upgrade -y
    apt-get install nginx -y
fi
systemctl daemon-reload
systemctl enable nginx
systemctl restart nginx

# PHP
echo "installing php"
if [[ ! -f /etc/php/7.2 ]]; then
    add-apt-repository -y ppa:ondrej/php
    apt-get update
    echo "Install PHP7.2.........."
    apt-get install -y php7.2 php7.2-fpm php7.2-cli php7.2-soap php7.2-curl php7.2-ds php7.2-xml php7.2-mbstring php7.2-igbinary php7.2-zip php7.2-intl php7.2-iconv && update-rc.d php7.2-fpm defaults
fi
echo "Reload PHP-FPM...."
systemctl daemon-reload
systemctl enable php7.2-fpm
systemctl restart php7.2-fpm
echo "Reload PHP-FPM....OK"

# X-DEBUG
echo "installing x-debug"
apt-get install -y php-pear php7.2-dev
pecl install xdebug

xdebug_path="zend_extension=\"$(find / -name 'xdebug.so' -type f 2>/dev/null)\""

sed -i.bak "/\[xdebug\]/a $xdebug_path" /vagrant/php.ini-fpm
mv /etc/php/7.2/fpm/php.ini /etc/php/7.2/fpm/php.ini-def
cp /vagrant/php.ini-fpm /etc/php/7.2/fpm/php.ini
rm /vagrant/php.ini-fpm
mv /vagrant/php.ini-fpm.bak /vagrant/php.ini-fpm

sed -i.bak "/\[xdebug\]/a $xdebug_path" /vagrant/php.ini-cli
mv /etc/php/7.2/cli/php.ini /etc/php/7.2/cli/php.ini-def
cp /vagrant/php.ini-cli /etc/php/7.2/cli/php.ini
rm /vagrant/php.ini-cli
mv /vagrant/php.ini-cli.bak /vagrant/php.ini-cli

systemctl restart php7.2-fpm


## Databases
locale-gen ru_RU
locale-gen ru_RU.UTF-8
update-locale

# MYSQL
#echo "installing mysql"
#export DEBIAN_FRONTEND=noninteractive
#apt-get -q -y install mysql-server

# PostgreSQL
# db_name(uncomment): DB=$1;
if [[ ! -f /usr/bin/psql ]]; then
    echo "Install PostgreSQL"
    echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/postgresql.list
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    apt-get update
    echo "Install POSTGRESSQL 10.........."
    apt-get install postgresql-10 -y

    su - postgres -c "psql -c \"alter user postgres with password 'postgres'\" "
    #su - postgres -c "psql -c \"create user $DB with password '$DB'\" "
    #su - postgres -c "psql -c \"alter user $DB with superuser \" "

    su - postgres -c "psql -c \"create user vagrant with password 'vagrant' \" "
    su - postgres -c "psql -c \"alter user vagrant with superuser \" "

    if ! su postgres -c "psql $DB -c '\q' 2>/dev/null"; then
        su postgres -c "createdb '$DB'"
        su postgres -c "createdb vagrant"
    fi
fi


# DOCKER
echo "installing docker"
if [[ ! -f /etc/docker ]]; then
    apt-get install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    apt-key fingerprint 0EBFCD88
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce
fi
echo "Verifying docker...."
docker run hello-world

# COMPOSER
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
RESULT=$?
mv composer.phar /usr/local/bin/composer
rm composer-setup.php

## install report

echo ""
echo "###### INSTALL REPORT ######"
echo ""
php -v
echo ""
echo ""
nginx -v
echo ""
echo ""
psql --version
echo ""
echo ""
composer --version
echo ""
echo ""
docker --version
echo ""
echo ""
uname -api
echo ""
echo ""
echo "######      ######"


exit $RESULT
