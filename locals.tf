locals {
  public_ssh_keys        = var.public_ssh_keys == null ? [{ name = "default", key = file("~/.ssh/id_rsa.pub") }] : var.public_ssh_keys
  host                   = "${yamldecode(local.kubeconfig)["clusters"][0]["cluster"]["server"]}"
  cluster_ca_certificate = "${base64decode(yamldecode(local.kubeconfig)["clusters"][0]["cluster"]["certificate-authority-data"])}"
  client_certificate     = "${base64decode(yamldecode(local.kubeconfig)["users"][0]["user"]["client-certificate-data"])}"
  client_key             = "${base64decode(yamldecode(local.kubeconfig)["users"][0]["user"]["client-key-data"])}"
}
