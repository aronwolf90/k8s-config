output "nodes" {
  value = {for node in hcloud_server.nodes: node.name => { "ipv4_address" = node.ipv4_address }}
}

output "load_balancer_ipv4_address" {
  value = hcloud_load_balancer.controller.ipv4
}
