output "corral_node_pools" {
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

output "rancher_host" {
  value = aws_route53_record.rancher.name
}