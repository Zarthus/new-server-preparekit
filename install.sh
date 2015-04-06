#!/bin/bash

# This installs a few packages for you, and some other nifty stuff
# As always, installation scripts are terribly user specified. But look around
# maybe you find something you like!
# Some interaction is required. But the key point is that we remember everything for you
# so you don't have to worry about it.

# Keep in mind. we're assuming this is a server. not a desktop
# the defaults may not be sane for desktops.

## Configuration section - edit these fields to your own desire.
OS="edit this" # Either "Debian" or "Ubuntu"

use_dotdeb="yes"  # Use dotdeb sources for PHP updates  (only relevant for debian)
use_mysql="yes"   # Use mysql sources for MySQL updates (only relevant for debian)

# These are the packages we want to install
WEBSERVER="nginx" # either apache2, lighttpd, or nginx
FIREWALL="ufw" # either empty or ufw

ESSENTIALS="build-essential curl emacs git grep less nano ntp mysql-client php5 python python3 ruby screen sudo tmux vim wget"
UTILITIES="atop cloc htop iftop ipcalc"
# consider adding the following packages to the list: postfix, vsftpd, fail2ban

RUBYGEMS="" # requires ruby, of course - suggested: gist
COMPOSER="yes" # requires php, of course either "yes" to globally install composer, or anything else
               # for also installing composer projects - suggested:

FUN="bsdgames cowsay toilet slurm sl"

if [[ $OS == "Debian" ]]; then
  EXTRAS="debian-goodies"
else
  EXTRAS=""
fi

apt_params="--assume-yes" # apt-get parameters to run

make_swap="" # empty for no swap, a swap size if yes (i.e. 4G or 512M)
SWAPPINESS=10 # swappiness, if you have no idea what you're doing, leave this as it is
CACHEPRESSURE=50 # also related to swap

copy_skel="yes" # Copy existing skel dir if exists
## End Configuration section.

if [[ $OS == "edit this" ]]; then
  echo "You have not edited the configuration."
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root."
  exit 1
fi

PACKAGES="$WEBSERVER $FIREWALL $ESSENTIALS $UTILITIES $FUN $EXTRAS"

echo "First we're going to do a quick update. Ensure everything we currently have is up to date."

apt-get update $apt_params
apt-get upgrade $apt_params

echo "Okay, before we go, there are some things we need you to do yourself."

# Change the timezone to something great.
# I trust you to make the right decision.
# (like UTC)
dpkg-reconfigure tzdata

if [[ $OS == "Debian" ]]; then
  if [[ $use_dotdeb == "yes" ]]; then
    echo  "" >> /etc/apt/sources.list
    echo "deb http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
    echo "deb-src http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list

    wget http://www.dotdeb.org/dotdeb.gpg
    apt-key add dotdeb.gpg

    echo "Added dotdeb.org sources to sources.list"
  fi

  if [[ $use_mysql == "yes" ]]; then
    wget https://dev.mysql.com/get/mysql-apt-config_0.3.3-1debian7_all.deb
    dpkg -i mysql-apt-config_0.3.3-1debian7_all.deb
    echo "Installed MySQL apt sources."
  fi
fi

apt-get update $apt_params

apt-get build-dep $WEBSERVER $apt_params

apt-get install $PACKAGES $apt_params

if [[ $RUBYGEMS != "" ]]; then
  gem install $RUBYGEMS

  echo "Gems: $RUBYGEMS"
  echo "Ruby gem installation completed."
fi

if [[ $COMPOSER != "" ]]; then
  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer

  if [[ $COMPOSER != "yes" ]]; then
    composer require --global $COMPOSER
  fi

  echo "Composer: $COMPOSER"
  echo "Composer is installed."
fi

if [[ $FIREWALL == "ufw" ]]; then
  ufw allow 22
  ufw allow 80
  ufw allow 443

  echo "Basic firewall rules configured. But firewall is still off"
fi

if [[ $make_swap != "" ]]; then
  fallocate -l $make_swap /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  swapon -s

  echo "/swapfile none swap sw 0 0" >> /etc/fstab
  echo "vm.swappiness=$SWAPPINESS" >> /etc/sysctl.conf
  echo "vm.vfs_cache_pressure=$CACHEPRESSURE" >> /etc/sysctl.conf
  echo "Swapfile generated at /swapfile"
fi

if [[ $copy_skel == "yes" ]]; then
  if [[ -d "skel" ]]; then
    shopt -s dotglob
    cp -r skel/* /etc/skel/
    shopt -u dotglob
    echo "Copied skeleton folder"
  fi
fi

echo
echo
echo "Packages installed ($PACKAGES)"
echo "Gems installed ($RUBYGEMS)"
echo "Composer (packages) installed ($COMPOSER)"
echo
echo
echo "There we are!"
echo
echo "We're done installing things. I'm leaving the rest over to you!"
echo "However, there are a few things you probably want to do at this point: "
echo
echo "Set SSH on a different port, disallow root login, generate some keypairs, "
echo "configure firewall rules, turn firewall on, configure mail/web/ftp/fail2ban servers.."
echo
echo "Also, don't forget to git config --global user.name and user.email"
echo
echo "Have fun!"