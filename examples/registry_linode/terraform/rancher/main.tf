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
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.23.0"
    }
  }
}

provider "random" {}
provider "linode" {
  token = var.linode_token
}

provider "docker" {
  host     = "ssh://root@${var.rancher_host}:22"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}

resource "docker_image" "rancher" {
  name = "rancher/rancher:${var.rancher_version}"
}

resource "docker_container" "rancher" {
  image = docker_image.rancher.image_id
  name  = "rancher"
  restart = "unless-stopped"
  privileged = true

  env = [
    "CATTLE_SYSTEM_DEFAULT_REGISTRY=${var.registry_host}",
    "CATTLE_SYSTEM_CATALOG=bundled",
    "CATTLE_BOOTSTRAP_PASSWORD=password"
  ]

  ports {
    internal = 80
    external = 80
    ip       = "0.0.0.0"
  }

  ports {
    internal = 443
    external = 443
    ip       = "0.0.0.0"
  }
}
