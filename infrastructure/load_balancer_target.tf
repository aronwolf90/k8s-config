resource "hcloud_load_balancer_target" "controller" {
  for_each = { for name, node in var.nodes : name => node if strcontains(node.role, "controller") }

  depends_on = [
    hcloud_server.nodes
  ]

  type             = "server"
  load_balancer_id = hcloud_load_balancer.controller.id
  server_id        = hcloud_server.nodes[each.key].id
}
