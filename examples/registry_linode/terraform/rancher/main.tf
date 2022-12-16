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
    rancher2 = {
      source  = "rancher/rancher2"
      version = "1.25.0"
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
  label   = "${var.corral_user_id}-${random_id.rancher_id.hex}"
  ssh_key = var.ssh_authorized_key
}

provider "rancher2" {
  alias     = "bootstrap"
  api_url   = "https://${var.rancher_host}"
  insecure  = true
  bootstrap = true
}

resource "rancher2_bootstrap" "admin" {
  provider         = rancher2.bootstrap
  initial_password = "admin"
  password         = "${var.rancher_password}"
  telemetry        = false
  depends_on       = [docker_container.rancher]
}

provider "rancher2" {
  alias     = "admin"
  api_url   = rancher2_bootstrap.admin.url
  token_key = rancher2_bootstrap.admin.token
  insecure  = true
}

provider "docker" {
  host     = "ssh://root@${var.rancher_host}"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}

resource "docker_image" "rancher" {
  name = "${var.registry_global_host}/rancher/rancher:${var.rancher_version}"
  # name = "rancher/rancher:${var.rancher_version}"
}

resource "docker_container" "rancher" {
  image = docker_image.rancher.image_id
  name  = "rancher"
  restart = "unless-stopped"
  privileged = true

  env = [
    "CATTLE_SYSTEM_DEFAULT_REGISTRY=${var.registry_global_host}",
    "CATTLE_SYSTEM_CATALOG=bundled",
    "CATTLE_BOOTSTRAP_PASSWORD=admin"
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

resource "rancher2_secret_v2" "registry_auth" {
  provider = rancher2.admin
  name = "registry-auth"
  type = "kubernetes.io/basic-auth"
  namespace = "fleet-default"
  cluster_id = "local"
  data = {
      password = "${var.password}"
      username = "corral"
  }
}

# resource "rancher2_cluster_v2" "custom_cluster" {
#   provider = rancher2.admin
#   name = "custom-cluster-privreg1"
#   kubernetes_version = "${var.kubernetes_version}"
#   rke_config {
#     registries {
#       configs {
#         hostname = "${var.registry_auth_host}"
#         auth_config_secret_name = rancher2_secret_v2.registry_auth.name
#         insecure = true
#         tls_secret_name = ""
#         ca_bundle = ""
#       }
#     }
#   }
# }

# resource "rancher2_cluster_sync" "custom_cluster" {
#     provider = rancher2.admin
#     cluster_id =  rancher2_cluster_v2.custom_cluster.cluster_v1_id
#     state_confirm = 25
#     wait_catalogs = true
#     depends_on = [
#       linode_instance.custom_nodes
#     ]
# }

# resource "linode_instance" "custom_nodes"{
#     count  = 3
#     label  = "${var.linode_resource_prefix}custom-n${count.index}-privreg" 
#     image  = "linode/ubuntu20.04"
#     region = "us-east"
#     type   = "g6-dedicated-4"
#     authorized_keys = [linode_sshkey.corral_public_ssh_key.ssh_key, linode_sshkey.public_ssh_key.ssh_key]
#     root_pass = var.linode_root_password

#     group = "privreg1"
#     tags = [ "privreg1" ]
#     swap_size = 256
#     private_ip = true

#     alerts {
#       cpu            = 0
#       io             = 0
#       network_in     = 0
#       network_out    = 0
#       transfer_quota = 0
#     }

#     connection {
#       host = self.ip_address
#       user = "root"
#       password = var.linode_root_password
#     }

#     provisioner "remote-exec" {
#         inline = [
#             "hostnamectl set-hostname ${var.linode_resource_prefix}customreg-n${count.index}",
#             "${nonsensitive(rancher2_cluster_v2.custom_cluster.cluster_registration_token[0].insecure_node_command)} --etcd --controlplane --worker"
#         ]
#     }

# }

# resource "rancher2_cloud_credential" "linode_rke2_global" {
#   provider = rancher2.admin
#   name = "linode-rke2-global"
#   linode_credential_config {
#     token = var.linode_token
#   }
# }

# resource "rancher2_machine_config_v2" "linode_rke2_control_plane_global" {
#   provider = rancher2.admin
#   generate_name = "global-rke2-cp"
#   linode_config {
#     create_private_ip = true
#     image = "linode/ubuntu20.04"
#     swap_size = 256
#     root_pass = var.linode_root_password
#   }
# }

# resource "rancher2_machine_config_v2" "linode_rke2_etcd_global" {
#   provider = rancher2.admin
#   generate_name = "global-rke2-etcd"
#   linode_config {
#     create_private_ip = true
#     image = "linode/ubuntu20.04"
#     swap_size = 256
#     root_pass = var.linode_root_password
#   }
# }

# resource "rancher2_machine_config_v2" "linode_rke2_worker_global" {
#   provider = rancher2.admin
#   generate_name = "global-rke2-worker"
#   linode_config {
#     create_private_ip = true
#     image = "linode/ubuntu20.04"
#     swap_size = 256
#     root_pass = var.linode_root_password
#   }
# }

# resource "rancher2_cluster_v2" "linode_rke2_global" {
#   provider = rancher2.admin
#   name = "privreg-rke2-global"
#   kubernetes_version = "${var.kubernetes_version}"
#   enable_network_policy = false
#   default_cluster_role_for_project_members = "user"
#   rke_config {
#     registries {
#       configs {
#         hostname = "${var.registry_auth_host}"
#         auth_config_secret_name = rancher2_secret_v2.registry_auth.name
#         insecure = true
#       }
#     }
#     machine_pools {
#       name = "poolcp"
#       cloud_credential_secret_name = rancher2_cloud_credential.linode_rke2_global.id
#       control_plane_role = true
#       etcd_role = false
#       worker_role = false
#       quantity = 1
#       machine_config {
#         kind = rancher2_machine_config_v2.linode_rke2_control_plane_global.kind
#         name = rancher2_machine_config_v2.linode_rke2_control_plane_global.name
#       }
#     }
#     machine_pools {
#       name = "pooletcd"
#       cloud_credential_secret_name = rancher2_cloud_credential.linode_rke2_global.id
#       control_plane_role = false
#       etcd_role = true
#       worker_role = false
#       quantity = 1
#       machine_config {
#         kind = rancher2_machine_config_v2.linode_rke2_etcd_global.kind
#         name = rancher2_machine_config_v2.linode_rke2_etcd_global.name
#       }
#     }
#     machine_pools {
#       name = "poolworker"
#       cloud_credential_secret_name = rancher2_cloud_credential.linode_rke2_global.id
#       control_plane_role = false
#       etcd_role = false
#       worker_role = true
#       quantity = 3
#       machine_config {
#         kind = rancher2_machine_config_v2.linode_rke2_worker_global.kind
#         name = rancher2_machine_config_v2.linode_rke2_worker_global.name
#       }
#     }
#   }
# }


resource "rancher2_cluster" "custom_cluster_rke1" {
  provider = rancher2.admin
  name = "custom-cluster-privreg-rke1"
  enable_cluster_monitoring = false
  rke_config {
    network {
      plugin = "canal"
    }
    private_registries {
      url = "${var.registry_auth_host}"
      user = "corral"
      password = "${var.password}"
      is_default = false
    }
    kubernetes_version = "${var.kubernetes_version_rke1}"
  }
}
resource "rancher2_cluster_sync" "custom_cluster" {
    provider = rancher2.admin
    cluster_id =  rancher2_cluster.custom_cluster_rke1.id
    state_confirm = 25
    wait_catalogs = true
    depends_on = [
      linode_instance.custom_nodes_rke1
    ]
}

resource "linode_instance" "custom_nodes_rke1"{
    count  = 3
    label  = "${var.linode_resource_prefix}custom-n${count.index}-privregrke1" 
    image  = "linode/ubuntu20.04"
    region = "us-east"
    type   = "g6-dedicated-4"
    authorized_keys = [linode_sshkey.corral_public_ssh_key.ssh_key, linode_sshkey.public_ssh_key.ssh_key]
    root_pass = var.linode_root_password

    group = "privregrke1"
    tags = [ "privregrke1" ]
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
            "set -x",
            "hostnamectl set-hostname ${var.linode_resource_prefix}customreg-n${count.index}",
            "wget https://releases.rancher.com/install-docker/${var.docker_version}.sh",
            "chmod +x ${var.docker_version}.sh",
            "bash ${var.docker_version}.sh",
            "docker login -u corral -p ${var.password} ${var.registry_auth_host}",
            "${rancher2_cluster.custom_cluster_rke1.cluster_registration_token[0].node_command} --address ${self.ip_address} --internal-address ${self.private_ip_address} --etcd --controlplane --worker"
        ]
    }

}