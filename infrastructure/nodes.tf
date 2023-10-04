resource "hcloud_ssh_key" "ssh_public_keys" {
  for_each = {for public_ssh_key in local.public_ssh_keys : public_ssh_key.name => public_ssh_key}

  name       = each.value.name
  public_key = each.value.key
}

resource "hcloud_server" "nodes" {
  for_each = var.nodes

  depends_on = [hcloud_ssh_key.ssh_public_keys]

  name        = each.key
  image       = each.value.image 
  location    = each.value.location
  server_type = each.value.server_type

  ssh_keys = [for name, ssh_public_key in hcloud_ssh_key.ssh_public_keys : ssh_public_key.id]
}
