#!/bin/bash
set -ex

DOWNLOAD_URL="https://github.com/rancher/rancher/releases/download/"

function corral_set() {
    echo "corral_set $1=$2"
}

function corral_log() {
    echo "corral_log $1"
}

corral_log "Build started for registry $CORRAL_registry_host"
echo "$CORRAL_corral_user_public_key" >> "$HOME"/.ssh/authorized_keys
echo "$CORRAL_valid_cert" | base64 -d > /opt/basic-registry/nginx_config/domain.crt
echo "$CORRAL_valid_key" | base64 -d > /opt/basic-registry/nginx_config/domain.key

corral_log "Downloading Dependencies"

if [ "True" = "$CORRAL_registry_auth" ]; then
    corral_log "Building registry with auth"
    
    USERNAME="corral"
    PASSWORD="$( echo $RANDOM | md5sum | head -c 12)"

    corral_set username "$USERNAME"
    corral_set password "$PASSWORD"

    htpasswd -Bbn "$USERNAME" "$PASSWORD" > /opt/basic-registry/nginx_config/registry.password
else
    corral_log "Building no auth registry"

    sed -i -e 's/auth_basic/#auth_basic/g' /opt/basic-registry/nginx_config/nginx.conf
    sed -i -e 's/add_header/#add_header/g' /opt/basic-registry/nginx_config/nginx.conf
fi

corral_log "Enabling docker registry systemd service"

systemctl enable docker-registry.service
systemctl start docker-registry.service

corral_log "Downloading Rancher registry scripts from release"

wget -O rancher-images.txt "${DOWNLOAD_URL}${CORRAL_rancher_version}"/rancher-images.txt
wget -O rancher-save-images.sh "${DOWNLOAD_URL}${CORRAL_rancher_version}"/rancher-save-images.sh
wget -O rancher-load-images.sh "${DOWNLOAD_URL}${CORRAL_rancher_version}"/rancher-load-images.sh
sed -i 's/docker save/# docker save /g' rancher-save-images.sh
sed -i 's/docker load/# docker load /g' rancher-load-images.sh
chmod +x rancher-save-images.sh 
chmod +x rancher-load-images.sh

corral_log "Saving images to host. Estimated time 1hr"

bash rancher-save-images.sh --image-list rancher-images.txt

if [ "True" = "$CORRAL_registry_auth" ]; then
    corral_log "Login to the registry to load images"

    docker login -u "$USERNAME" -p "$PASSWORD" "$CORRAL_registry_host"
else
    corral_log "No login needed to load images"
fi

corral_log "Loading images to registry. Estimated time 1hr"

bash rancher-load-images.sh --image-list rancher-images.txt --registry "$CORRAL_registry_host"

corral_log "Registry username: $USERNAME"
corral_log "Registry password: $PASSWORD"
corral_log "Registry Host: $CORRAL_registry_host"
