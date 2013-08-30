#!/bin/bash

# Base script
# - MySql settings:
# -- db_name boxdatabase
# -- db_user boxuser 
# -- db_pass boxpassword 

# Check for argument presence
argument_lists=( "$@" )
for i in "${argument_lists[@]}"
do
  if [[ $i = "-gui" ]] ; then
    GUI = "yes"
  elif [[ $i = "-nolamp" ]]; then
    NOLAMP = "yes"
  fi
done

# Installation start
# Update
apt-get update
# Needed for add repo
apt-get install -y python-software-properties
# Extra packages
apt-get install -y curl vim git-core
# For replacing \r new line windows specific
apt-get install -y dos2unix

# Gui mode - packages
if [[ "$GUI" = "yes" ]]; then
  add-apt-repository ppa:webupd8team/sublime-text-2
  apt-get install -y sublime-text-2
  apt-get install -y vim-gnome lubuntu-desktop
fi

# Install (L)AMP stack - Apache, MySQL, PHP 
if [[ ! "$NOLAMP" = "yes" ]]; then
  apt-get install -y apache2
  apt-get install -y php5
  apt-get install -y libapache2-mod-php5
  apt-get install -y php5-mysql php5-curl php5-gd php5-intl php-pear php5-imap php5-mcrypt php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-apc

  # Delete default apache web dir and symlink mounted vagrant dir from host machine
  rm -rf /var/www
  mkdir /vagrant/httpdocs
  ln -fs /vagrant/httpdocs /var/www

  # Replace contents of default Apache vhost
  # --------------------
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/var/www"
  ServerName localhost
  <Directory "/var/www">
    Options FollowSymLinks  
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

  echo "$VHOST" > /etc/apache2/sites-enabled/000-default

  a2enmod rewrite
  service apache2 restart

  # Mysql
  # --------------------
  # Ignore the post install questions
  export DEBIAN_FRONTEND=noninteractive
  # Install MySQL quietly
  apt-get -q -y install mysql-server-5.5

  mysql -u root -e "CREATE DATABASE IF NOT EXISTS boxdatabase"
  mysql -u root -e "GRANT ALL PRIVILEGES ON boxdatabase.* TO 'boxuser'@'localhost' IDENTIFIED BY 'boxpassword'"
  mysql -u root -e "FLUSH PRIVILEGES"
fi