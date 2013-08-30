#!/bin/bash

# Magento CE 1.7.0.2 installation script (based on Cookieflow)
# admin_username: admin
# admin_password: password123
# --------------------
# http://www.magentocommerce.com/wiki/1_-_installation_and_configuration/installing_magento_via_shell_ssh

# Download and extract
if [ ! -f "/vagrant/httpdocs/index.php" ]; then
  if [ ! -d "/vagrant/httpdocs" ]; then
    mkdir -p "/vagrant/httpdocs"
  fi
  cd /vagrant/httpdocs
  wget http://www.magentocommerce.com/downloads/assets/1.7.0.2/magento-1.7.0.2.tar.gz
  tar -zxvf magento-1.7.0.2.tar.gz
  mv magento/* magento/.htaccess .
  chmod -R o+w media var
  chmod o+w app/etc
  # Clean up downloaded file and extracted dir
  rm -rf magento*
fi

# Run installer
if [ ! -f "/vagrant/httpdocs/app/etc/local.xml" ]; then
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