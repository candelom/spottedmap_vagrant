#!/bin/bash

NODE_VER=v0.10.29

echo "Provisioning virtual machine..."

echo "updating apt-get"
apt-get update > /dev/null

echo "Installing tools"
apt-get install git-core curl build-essential openssl libssl-dev -y > /dev/null


echo "Installing node"
git clone https://github.com/joyent/node.git
cd node
git checkout $NODE_VER

./configure
make
sudo make install



echo "Installing Nginx"
apt-get install nginx -y > /dev/null
cp -u /spottedmap_vagrant/conf/nginx/spottedmap /etc/nginx/sites-available/spottedmap
ln -s /etc/nginx/sites-available/spottedmap /etc/nginx/sites-enabled/spottedmap
rm /etc/nginx/sites-enabled/default

service nginx reload


echo "Installing supervisor"
apt-get install supervisor -y > /dev/null

echo "Starting supervisor"
service supervisor restart











