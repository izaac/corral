terraform {
  required_version = ">= 0.13"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.27.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.15.1"
    }
  }
}

provider "random" {}
provider "linode" {
  token = var.linode_token
}

resource "random_id" "registry_id" {
  byte_length       = 6
}

resource "random_id" "rancher_id" {
  byte_length       = 6
}

resource "linode_sshkey" "corral_public_ssh_key" {
  label   = "${var.corral_user_id}-${random_id.registry_id.hex}"
  ssh_key = var.corral_public_key
}

resource "linode_sshkey" "public_ssh_key" {
  label   = "${var.corral_user_id}-${random_id.registry_id.hex}"
  ssh_key = var.ssh_authorized_key
}

resource "linode_instance" "registry" {
    count = 1
    label = "${var.corral_user_id}-${random_id.registry_id.hex}-registry"
    image = "linode/ubuntu20.04"
    region = "us-east"
    type = "g6-standard-4"
    authorized_keys = [linode_sshkey.corral_public_ssh_key.ssh_key, linode_sshkey.public_ssh_key.ssh_key]
    root_pass = var.linode_root_password

    group = "hosted_registry"
    tags = [var.corral_user_id, random_id.registry_id.hex]
    swap_size = 256
    private_ip = true

    alerts {
    cpu            = 0
    io             = 0
    network_in     = 0
    network_out    = 0
    transfer_quota = 0
  }

  connection {
      host = self.ip_address
      user = "root"
      password = var.linode_root_password
  }

  provisioner "remote-exec" {
   inline = [
       "wget https://releases.rancher.com/install-docker/${var.docker_version}.sh",
       "chmod +x ${var.docker_version}.sh",
       "bash ${var.docker_version}.sh",
       "apt-get install -y apache2-utils docker-compose"
   ]
  }
}

resource "aws_route53_record" "registry" {
  zone_id = var.aws_zone_id
  name    = "${var.corral_user_id}-${random_id.registry_id.hex}.${var.aws_domain}"
  type    = "A"
  ttl     = "10"
  records = [linode_instance.registry[0].ip_address]
}

resource "linode_instance" "rancher" {
    count = 1
    label = "${var.corral_user_id}-${random_id.rancher_id.hex}-rancher"
    image = "linode/ubuntu20.04"
    region = "us-east"
    type = "g6-standard-4"
    authorized_keys = [linode_sshkey.corral_public_ssh_key.ssh_key, linode_sshkey.public_ssh_key.ssh_key]
    root_pass = var.linode_root_password

    group = "hosted_registry"
    tags = [var.corral_user_id, random_id.rancher_id.hex]
    swap_size = 256
    private_ip = true

    alerts {
    cpu            = 0
    io             = 0
    network_in     = 0
    network_out    = 0
    transfer_quota = 0
  }

  connection {
      host = self.ip_address
      user = "root"
      password = var.linode_root_password
  }

  provisioner "remote-exec" {
   inline = [
       "wget https://releases.rancher.com/install-docker/${var.docker_version}.sh",
       "chmod +x ${var.docker_version}.sh",
       "bash ${var.docker_version}.sh"
   ]
  }
}

resource "aws_route53_record" "rancher" {
  zone_id = var.aws_zone_id
  name    = "${var.corral_user_id}-${random_id.rancher_id.hex}.${var.aws_domain}"
  type    = "A"
  ttl     = "10"
  records = [linode_instance.rancher[0].ip_address]
}