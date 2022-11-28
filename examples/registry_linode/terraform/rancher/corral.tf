variable "corral_name" {} // name of the corral being created
variable "corral_user_id" {} // how the user is identified (usually github username)
variable "corral_user_public_key" {} // the users public key
variable "corral_public_key" {} // The corrals public key.  This should be installed on every node.
variable "corral_private_key" {} // The corrals private key.

// Package
variable "linode_token" {}
variable "aws_zone_id" {}
variable "aws_domain" {}
variable "linode_root_password" {}
variable "registry_auth" {}
variable "rancher_host" {}
variable "registry_host" {}
variable "rancher_version" {}
variable "rancher_password" {}