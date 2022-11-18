output "corral_rancher_node_pools" {
  value = {
    rancher = [
    for node in linode_instance.rancher : {
      name = node.label
      user = "root"
      address = node.ip_address
    }
    ]
  }
}

output "corral_registry_node_pools" {
  value = {
    registry = [
    for node in linode_instance.registry : {
      name = node.label
      user = "root"
      address = node.ip_address
    }
    ]
  }
}

output "registry_host" {
  value = aws_route53_record.registry.name
}

output "rancher_host" {
  value = aws_route53_record.rancher.name
}