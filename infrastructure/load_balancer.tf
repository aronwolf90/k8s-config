resource "hcloud_load_balancer" "controller" {
  name               = "controller"
  load_balancer_type = "lb11"
  depends_on         = [hcloud_server.nodes]
  location           = "fsn1"
}
