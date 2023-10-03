output "nodes" {
  value = [for node in hcloud_server.nodes: {
    "name": node.name,
    "ipv4_address" = node.ipv4_address,
    "role" = {for node in var.nodes: node.name => node.role}[node.name],
  }]
}

output "load_balancer_ipv4_address" {
  value = hcloud_load_balancer.controller.ipv4
}
