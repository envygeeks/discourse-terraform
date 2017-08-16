#!/bin/bash -l

sudo apt-get update && sudo apt-get dist-upgrade \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  --assume-yes

# --
# Setup Docker
# --
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88; repo=https://download.docker.com/linux/ubuntu
sudo add-apt-repository "deb [arch=amd64] $repo $(lsb_release -cs) stable"
sudo apt-get update && sudo apt-get install docker-ce -y \
  --no-install-recommends

# --
# Clone Discourse
# --
sudo mkdir -p /opt/discourse && sudo chown ubuntu.ubuntu /opt/discourse
git clone https://github.com/discourse/discourse_docker.git /opt/discourse
cp ~/web.yml /opt/discourse/containers/web.yml
rm -rf ~/setup.sh ~/web.yml
