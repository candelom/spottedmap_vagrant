#!/bin/bash
NODE_VER=v0.10.29
USER=mattiacandeloro

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


echo "Creating group webadmin"
groupadd webadmin

echo "Adding user to group"
useradd -G webadmin $USER

echo "Creating data folder"
cd /var/
mkdir www
chmod g+rwx ./www/
cd www/

echo "Setup ssl cert"
mkdir ssl_cert
cp -r /vagrant/conf/ssl_cert/ /var/www/

echo "Setup auto ops and supervisor"
mkdir spottedmap_auto_ops
cd spottedmap_auto_ops/
mkdir etc
cp -u /vagrant/conf/supervisor/spottedmap_web.conf /var/www/spottedmap_auto_ops/etc/supervisord.conf



echo "Assign data folder permissions"
chown -R $USER:webadmin /var/www


echo "Installing Nginx"
apt-get install nginx -y > /dev/null
cp -u /vagrant/conf/nginx/spottedmap_web /etc/nginx/sites-available/spottedmap_web
ln -s /etc/nginx/sites-available/spottedmap_web /etc/nginx/sites-enabled/spottedmap_web
rm /etc/nginx/sites-enabled/default


echo "Reloading nginx"
service nginx reload
service nginx start

echo "Installing supervisor"
apt-get install supervisor -y > /dev/null













