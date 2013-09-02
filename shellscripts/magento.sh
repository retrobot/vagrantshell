#!/bin/bash

# Magento CE 1.7.0.2 installation script (based on Cookieflow)
# admin_username: admin
# admin_password: password123
# --------------------
# http://www.magentocommerce.com/wiki/1_-_installation_and_configuration/installing_magento_via_shell_ssh

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi
  
# Check for argument presence
    if [[ $1 = "--help" || $1 = "" ]]; then
        echo "Usage:"
        echo "  --help          run this help"
        echo " -c --create-db     database creation"
        echo " -d --download      download magento"
        echo " -p --permissions    Set permissions"
        echo " -a --apache-setup  basic apache setup"
        echo " -i --install       install magento"
    fi

    argument_lists=( "$@" )
    for i in "${argument_lists[@]}"; do
      if [[ $i = "--create-db" ]] ; then
        CREATE_DB="yes"
      elif [[ $i = "--apache-setup" ]]; then
        APACHE_SETUP="yes" 
      elif [[ $i = "--create-db" ]] ; then
        DOWNLOAD="yes"
      elif [[ $i = "--permissions" || $i = "-p" ]] ; then
        PERMISSIONS="yes"
      elif [[ $i = "--install" ]]; then
        INSTALL="yes"
      elif [[ $i = "--ttt" ]]; then
        TTT="yes"
      fi 
    done

if [[ $APACHE_SETUP = "yes" ]]; then
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

# Restarting services
  a2enmod rewrite
  service apache2 restart
fi


if [[ $CREATE_DB = "yes" ]]; then
# Create database
  mysql -uroot -proot -e"CREATE DATABASE IF NOT EXISTS boxdatabase"
  mysql -uroot -proot -e"GRANT ALL PRIVILEGES ON boxdatabase.* TO 'boxuser'@'localhost' IDENTIFIED BY 'boxpassword'"
  mysql -uroot -proot -e"FLUSH PRIVILEGES"
fi

if [[ $DOWNLOAD = "yes" ]]; then
# Download and extract
if [[ ! -f "/vagrant/httpdocs/index.php" ]]; then
  if [[ ! -d "/vagrant/httpdocs" ]]; then
    mkdir -p "/vagrant/httpdocs"
  fi
  cd /vagrant/httpdocs
  wget http://www.magentocommerce.com/downloads/assets/1.7.0.2/magento-1.7.0.2.tar.gz
  tar -zxvf magento-1.7.0.2.tar.gz
  mv magento/* magento/.htaccess .
fi
fi

if [[ $PERMISSIONS = "yes" ]]; then
  find . -type f -exec chmod 644 {} \;
  find . -type d -exec chmod 755 {} \;
  chmod -R o+w media var
  chmod o+w app/etc
  chmod 550 pear
fi

if [[ $DOWNLOAD = "yes" ]]; then
  # Clean up downloaded file and extracted dir
  rm -rf magento*
fi


if [[ $INSTALL = "yes" ]]; then
# Run installer
if [[ ! -f "/vagrant/httpdocs/app/etc/local.xml" ]]; then
  cd /vagrant/httpdocs
  sudo /usr/bin/php -f install.php -- --license_agreement_accepted yes \
  --locale en_GB --timezone "Europe/London" --default_currency GBP \
  --db_host localhost --db_name boxdatabase --db_user boxuser --db_pass boxpassword \
  --url "http://127.0.0.1:8080/" --use_rewrites yes \
  --use_secure no --secure_base_url "http://127.0.0.1:8080/" --use_secure_admin no \
  --skip_url_validation yes \
  --admin_lastname Owner --admin_firstname Store --admin_email "admin@example.com" \
  --admin_username admin --admin_password password123
fi
fi

if [[ $TTT ]]; then
    echo Works
fi

