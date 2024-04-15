resource "hcloud_ssh_key" "ssh_public_keys" {
  for_each = { for public_ssh_key in local.public_ssh_keys : public_ssh_key.name => public_ssh_key }

  name       = each.value.name
  public_key = each.value.key
}
