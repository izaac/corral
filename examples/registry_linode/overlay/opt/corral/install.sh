#!/bin/bash
set -ex

function corral_set() {
    echo "corral_set $1=$2"
}

function corral_log() {
    echo "corral_log $1"
}

corral_log "No auth registry hostname ${CORRAL_registry_host}"
echo "$CORRAL_corral_user_public_key" >> "$HOME"/.ssh/authorized_keys

echo "$CORRAL_valid_cert" | base64 -d > /opt/basic-registry/nginx_config/domain.crt
echo "$CORRAL_valid_key" | base64 -d > /opt/basic-registry/nginx_config/domain.key

apt-get update -y
apt-get install -y apache2-utils docker-compose

wget -O rancher-images.txt https://github.com/rancher/rancher/releases/download/"$CORRAL_rancher_version"/rancher-images.txt
wget -O rancher-save-images.sh https://github.com/rancher/rancher/releases/download/"$CORRAL_rancher_version"/rancher-save-images.sh
wget -O rancher-load-images.sh https://github.com/rancher/rancher/releases/download/"$CORRAL_rancher_version"/rancher-load-images.sh

sed -i '58d' rancher-save-images.sh
sed -i '76d' rancher-load-images.sh

chmod +x rancher-save-images.sh 
chmod +x rancher-load-images.sh
bash rancher-save-images.sh --image-list rancher-images.txt

systemctl enable docker-registry.service
systemctl start docker-registry.service

bash rancher-load-images.sh --image-list rancher-images.txt --registry "$CORRAL_registry_host"

# USERNAME="corral"
# PASSWORD="$( echo $RANDOM | md5sum | head -c 12)"  # it is best practice to generate passwords for every distinct corral

# corral_set username "$USERNAME"
# corral_set password "$PASSWORD"

# htpasswd -Bbn $USERNAME $PASSWORD > /etc/docker/registry/htpasswd
