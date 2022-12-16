output "corral_node_pools" {
  value = {
    rancher = [
    for node in linode_instance.rancher : {
      name = node.label
      user = "root"
      address = node.ip_address
    }
    ]
    registry = [
    for node in linode_instance.registry : {
      name = node.label
      user = "root"
      address = node.ip_address
    }
    ]
  }
}

output "rancher_host" {
  value = aws_route53_record.rancher.name
}

output "registry_global_host" {
  value = aws_route53_record.registry-global.name
}

output "registry_auth_host" {
  value = aws_route53_record.registry-cluster-auth.name
}

output "registry_noauth_host" {
  value = aws_route53_record.registry-cluster-noauth.name
}