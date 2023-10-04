output "nodes" {
  value = { for key, node in hcloud_server.nodes : key => merge({"ipv4" = node.ipv4_address}, var.nodes[key]) }
}

output "load_balancer_ipv4_address" {
  value = hcloud_load_balancer.controller.ipv4
}
