#!/bin/bash

# Base script - based on vagrantpress
# - MySql settings:
# ---- db_name boxdatabase
# ---- db_user boxuser 
# ---- db_pass boxpassword 
# - MySql:
# - u root -p root

#######
# Initial settings
  # For calculating time of script to run
    start_seconds=`date +%s`
  # Check if run by root  
    if [ "$(id -u)" != "0" ]; then
      echo "This script must be run as root" 1>&2
      exit 1
    fi
  # Pinging google to check if internet connection present
    ping_result=`ping -c 2 8.8.4.4 2>&1`
    if [[ $ping_result != *bytes?from* ]]; then
      ping_result=`ping -c 2 4.2.2.2 2>&1`
    fi
  # Check for argument presence
    argument_lists=( "$@" )
    for i in "${argument_lists[@]}"; do
      if [[ $i = "-gui" ]] ; then
        GUI="yes"
      elif [[ $i = "-lamp" ]]; then
        LAMP="yes"
      fi
    done

# list of packages to install
  apt_package_install_list=()
# Check list - before installing
  apt_package_check_list=(
    python-software-properties
    # utilities
    imagemagick
    curl
    vim
    git-core
    unzip
    # dos endings conversion tool (\r)
    dos2unix
    # for grunt / 'libcompass-ruby1.8' available too
    libcompass-ruby
    ruby-compass
    # for node
    g++
    nodejs
)

# Gui mode - packages
  if [[ "$GUI" = "yes" ]]; then
    gui_list=( 
      sublime-text
      vim-gnome
      # lubuntu-desktop
      lxde
    )
    for guipkg in ${gui_list[@]}; do 
      apt_package_check_list+=($guipkg)
    done
  fi

# Install (L)AMP stack - Apache, MySQL, PHP 
  if [[ "$LAMP" = "yes" ]]; then
    lamp_list=(
      # Mysql base
      mysql-client mysql-server
      apache2
      php5
      libapache2-mod-php5
      php5-mysql php5-curl php5-gd php5-intl php-pear php5-imap
      php5-mcrypt php5-ming php5-ps php5-pspell php5-recode
      php5-snmp php5-sqlite php5-tidy
      php5-xmlrpc php5-xsl php-apc
    )
      for lamppkg in ${lamp_list[@]}; do 
        apt_package_check_list+=($lamppkg)
      done
  fi

# Looping through array of packages to install. If not installed add to array
  for pkg in "${apt_package_check_list[@]}"; do
    package_version=`dpkg -s $pkg 2>&1 | grep 'Version:' | cut -d " " -f 2`
    if [[ $package_version != "" ]]
    then
      space_count=`expr 20 - "${#pkg}"` #11
      pack_space_count=`expr 30 - "${#package_version}"`
      real_space=`expr ${space_count} + ${pack_space_count} + ${#package_version}`
      printf " * $pkg %${real_space}.${#package_version}s ${package_version}\n"
    else
      echo " *" $pkg [not installed]
      apt_package_install_list+=($pkg)
    fi
  done

# MySQL
#
# Use debconf-set-selections to specify the default password for the root MySQL
# account. This runs on every provision, even if MySQL has been installed. If
# MySQL is already installed, it will not affect anything. The password in the
# following two lines *is* actually set to the word 'blank' for the root user.
echo mysql-server mysql-server/root_password password root | debconf-set-selections
echo mysql-server mysql-server/root_password_again password root | debconf-set-selections

# Provide our custom apt sources before running `apt-get update`
# cp /srv/config/apt-source-append.list /etc/apt/sources.list.d/ | echo "Linked custom apt sources"
ln -sf /srv/config/apt-source-append.list /etc/apt/sources.list.d/extra-sources.list | echo "Linked custom apt sources"

# Install when interent connection present
  if [[ $ping_result == *bytes?from* ]] ; then
    if [ ${#apt_package_install_list[@]} = 0 ]; then
      echo -e "No apt packages to install.\n"
    else
      # Add the public keys for the packages from non standard sources via apt source.list
      # Nginx.org nginx key ABF5BD827BD9BF62
      gpg -q --keyserver keyserver.ubuntu.com --recv-key ABF5BD827BD9BF62
      gpg -q -a --export ABF5BD827BD9BF62 | apt-key add -
      # Launchpad Subversion key EAA903E3A2F4C039
      gpg -q --keyserver keyserver.ubuntu.com --recv-key EAA903E3A2F4C039
      gpg -q -a --export EAA903E3A2F4C039 | apt-key add -
      # Launchpad PHP key 4F4EA0AAE5267A6C
      gpg -q --keyserver keyserver.ubuntu.com --recv-key 4F4EA0AAE5267A6C
      gpg -q -a --export 4F4EA0AAE5267A6C | apt-key add -
      # Launchpad git key A1715D88E1DF1F24
      gpg -q --keyserver keyserver.ubuntu.com --recv-key A1715D88E1DF1F24
      gpg -q -a --export A1715D88E1DF1F24 | apt-key add -
      # Launchpad nodejs key C7917B12
      gpg -q --keyserver keyserver.ubuntu.com --recv-key C7917B12
      gpg -q -a --export  C7917B12  | apt-key add -
      # Sublime text
      gpg -q --keyserver keyserver.ubuntu.com --recv-key EEA14886
      gpg -q -a --export  EEA14886  | apt-key add -

      # update all of the package references before installing anything
      echo "Running apt-get update..."
      apt-get update --assume-yes

      # install required packages
      echo "Installing apt-get packages..."

      echo "TEST IF IT SEES PACKAGES LIST"
      echo ${apt_package_install_list[@]}
      apt-get install --assume-yes ${apt_package_install_list[@]}

      # Clean up apt caches
      apt-get clean
    fi


  # Composer installation / updating
    if composer --version | grep -q 'Composer version'; then
        echo "Updating Composer..."
        composer self-update
      else
        echo "Installing Composer..."
        curl -sS https://getcomposer.org/installer | php
        chmod +x composer.phar
        mv composer.phar /usr/local/bin/composer
    fi

  # Capistrano installation / updating
    if capify -v | grep -q 'capify'; then
	echo "Capistrano is installed"
    else
	echo "Installing capistrano"
	gem install capistrano
	gem install capistrano-ext
    fi

  # Grunt installation
    if grunt --version ; then
        echo "Updating Grunt CLI"
        npm update -g grunt-cli
      else
        echo "Installing Grunt CLI"
        npm install -g grunt-cli
    fi

  else
    echo -e "\nNo network available, skipping network installations"
  fi


### Specific files with DATA install
####
  if [[ $ping_result == *bytes?from* ]]; then
  # Git repos
    echo "Clone bash and vim settings plus scripts "
    git clone git://github.com/retrobot/bash /home/vagrant/mybash
    cp -rf /home/vagrant/mybash/* /home/vagrant/mybash/.* /home/vagrant/
    chown -R vagrant:vagrant ~/
  
  # Grunt install into specific project
   git clone git://github.com/retrobot/grunt /vagrant/httpdocs/
    # git clone git://github.com/retrobot/grunt-framework /vagrant/httpdocs/
    # Grunfile.js/coffee and package.json will be copied to project
   mv /vagrant/httpdocs/grunt/* /vagrant/httpdocs/
    # This will install all dependancies regarding to package.json
   
   cd /vagrant/httpdocs/ 
   npm install
    # command: npm install <module> --save-dev  
    # will install plugin to project and append command to package.json
    # 'grunt init' will create project specific package.json
    # This will start grunt
    # grunt
    
    # increase number of files watched - avoid ENOSPC error
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
  else
    echo -e "\nNo network available, skipping network installations"
  fi
####



if [[ "$LAMP" = "yes" ]]; then
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

  # Mysql
  # --------------------
  # Ignore the post install questions
  export DEBIAN_FRONTEND=noninteractive
  # Install MySQL quietly
  apt-get -q -y install mysql-server-5.5

  mysql -u root -p root -e "CREATE DATABASE IF NOT EXISTS boxdatabase"
  mysql -u root -p root -e "GRANT ALL PRIVILEGES ON boxdatabase.* TO 'boxuser'@'localhost' IDENTIFIED BY 'boxpassword'"
  mysql -u root -p root -e "FLUSH PRIVILEGES"
fi
