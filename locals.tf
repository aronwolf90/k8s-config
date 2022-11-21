locals {
  public_ssh_keys            = var.ssh_public_keys == null ? [{ name = "default", key = file("~/.ssh/id_rsa.pub") }] : var.ssh_public_keys
  public_ssh_key_list        = [ for public_ssh in local.public_ssh_keys : public_ssh.key ]
  transformed_master_nodes   = { for node in var.master_nodes : node.name => { image = node.image } }
  transfored_public_ssh_keys = { for public_ssh_key in local.public_ssh_keys : public_ssh_key.name => public_ssh_key.key }
  worker_public_ssh_key      = var.worker_public_ssh_key == null ? local.public_ssh_keys[0].name : var.worker_public_ssh_key 
}
