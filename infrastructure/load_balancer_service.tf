resource "hcloud_load_balancer_service" "load_balancer_service_6443" {
  depends_on = [hcloud_load_balancer.controller]

  load_balancer_id = hcloud_load_balancer.controller.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

resource "hcloud_load_balancer_service" "load_balancer_service_8132" {
  depends_on = [hcloud_load_balancer.controller]

  load_balancer_id = hcloud_load_balancer.controller.id
  protocol         = "tcp"
  listen_port      = 8132
  destination_port = 8132
}

resource "hcloud_load_balancer_service" "load_balancer_service_9443" {
  depends_on = [hcloud_load_balancer.controller]

  load_balancer_id = hcloud_load_balancer.controller.id
  protocol         = "tcp"
  listen_port      = 9443
  destination_port = 9443
}
