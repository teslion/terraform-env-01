#!/bin/bash

sudo apt-get update -y
sudo apt-get install apache2 -y
sudo systemctl enable apache2
sudo systemctl start apache2
sudo apt-get install -y php7.2-cli
sudo apt-get install -y hhvm
sudo apt-get install -y python
sudo echo "I'm alive!" > /var/www/html/healthcheck.html
#sudo echo "I'm alive!" > /var/www/public_html/public/healthcheck.html

sudo apt-get install -yq apt-utils
sudo apt-get install -yq unzip
sudo apt-get install -yq curl
sudo apt-get install -yq git
sudo apt-get install -yq vim

sudo apt-get install  -yq  ghostscript
sudo apt-get install  -yq  mysql-client
sudo apt-get install  -yq  iputils-ping
sudo apt-get install -yq locales
sudo apt-get install -yq sqlite3
sudo apt-get install -yq ca-certificates

sudo hostnamectl set-hostname 'webserver-ec2-terraform-test'
