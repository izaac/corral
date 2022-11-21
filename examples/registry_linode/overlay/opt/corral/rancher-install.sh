#!/bin/bash
set -ex

function corral_set() {
    echo "corral_set $1=$2"
}

function corral_log() {
    echo "corral_log $1"
}

corral_log "Build started for Rancher with private registry $CORRAL_registry_host"
corral_log "Downloading Dependencies"

apt-get update -y
apt-get install -y apache2-utils docker-compose