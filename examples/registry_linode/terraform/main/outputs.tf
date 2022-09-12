output "corral_node_pools" {
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