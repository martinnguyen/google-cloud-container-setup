#!/bin/bash
###############
#
# Bash script for creating main proxy server and holder of the docker containers.
# Author: Bob van Luijt
# Readme: https://github.com/bobvanluijt/Docker-multi-wordpress-hhvm-google-cloud
#
###############

# Run the script as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# ask for database ip host
echo "What is the host ip of the database: "
read DBHOST

# ask for internal ip host
echo "What is the internal IP of this host (like: 10.132.0.1): "
read INTERNALHOST

# setup for gcloud (add debs)
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Update
apt-get update -qq -y

# Install security updates
apt-get unattended-upgrades -d -qq -y

# Install MYSQL client and set pass and host
apt-get install mysql-client-5.7 -qq -y
echo "What is the mysql root password: "
mysql_config_editor set --login-path=local --host=${DBHOST} --user=root --password

# Install jq for parsing jquery
apt-get install jq -qq -y

# Install gcloud
apt-get install google-cloud-sdk
gcloud init

# Install Docker deps
apt-get install apt-transport-https ca-certificates -qq -y

# Add docker keys
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

# Update with docker keys
apt-get update -qq -y

# Create file docker.list
touch /etc/apt/sources.list.d/docker.list

# Add Ubuntu Xenial repo
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" >> /etc/apt/sources.list.d/docker.list

# Update after adding Docker repo
apt-get update -qq -y

# Double check and remove if above already exsists
apt-get purge lxc-docker -qq -y

# Run Cache
apt-cache policy docker-engine

# Install ubuntu image
apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -qq -y

# Install docker engine
apt-get install docker-engine -qq -y

# Start the Docker service
service docker start

# Install NGINX
apt-get install nginx -qq -y

# Install SSL
apt-get install letsencrypt -qq -y

# Make main dir to connect Wordpress wp-content directories to
mkdir -m 777 -p /var/wordpress-content

# Clear screen
clear

# Create Docker manager
docker swarm init --advertise-addr ${INTERNALHOST}
echo "USE THE ABOVE COMMAND TO SETUP NODES, SAVE THE TOKEN SECURE"
