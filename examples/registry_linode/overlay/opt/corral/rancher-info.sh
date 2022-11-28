#!/bin/bash
set -ex

function corral_set() {
    echo "corral_set $1=$2"
}

function corral_log() {
    echo "corral_log $1"
}

corral_log "Rancher private registry: $CORRAL_registry_host"
corral_log "Rancher server: https://$CORRAL_rancher_host"