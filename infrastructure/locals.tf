locals {
  public_ssh_keys = var.public_ssh_keys == null ? [{ name = "default", key = file("~/.ssh/id_rsa.pub") }] : var.public_ssh_keys
}
