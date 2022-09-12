#!/bin/bash
set -ex

# function corral_set() {
#     echo "corral_set $1=$2"
# }

# function corral_log() {
#     echo "corral_log $1"
# }

echo $CORRAL_corral_user_public_key >> $HOME/.ssh/authorized_keys

apt-get update -y
apt-get install -y apache2-utils

# USERNAME="corral"
# PASSWORD="$( echo $RANDOM | md5sum | head -c 12)"  # it is best practice to generate passwords for every distinct corral

# corral_set username $USERNAME
# corral_set password $PASSWORD

# htpasswd -Bbn $USERNAME $PASSWORD > /etc/docker/registry/htpasswd

# sed -i "s/HOSTNAME/${CORRAL_registry_host}/g" /etc/docker/registry/config.yml

# # generate self signed certificates
# openssl req -x509 \
#             -newkey rsa:4096 \
#             -sha256 \
#             -days 3650 \
#             -nodes \
#             -keyout /etc/docker/registry/ssl/registry.key \
#             -out /etc/docker/registry/ssl/registry.crt \
#             -subj "/CN=${CORRAL_registry_host}" \
#             -addext "subjectAltName=DNS:${CORRAL_registry_host}"

# #corral_log "This registry uses self signed certificates please add {\"insecure_registries\":[\"${CORRAL_registry_host}\"]} to /etc/docker/daemon.json."

# systemctl enable registry
# systemctl start registry
