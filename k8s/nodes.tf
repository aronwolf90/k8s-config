resource "null_resource" "nodes" {
  for_each = {for node in var.nodes: node.name => node}

  triggers = {
    ipv4 = each.value.ipv4
    name = each.value.name
    private_ssh_key_path = var.private_ssh_key_path
  }

  connection {
    host        = self.triggers.ipv4
    type        = "ssh"
    user        = "root"
    private_key = file(self.triggers.private_ssh_key_path)
  }

  # Restic need the folder on this location to make it work 
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/lib/kubelet/",
      "ln -sf /var/lib/k0s/kubelet/pods/ /var/lib/kubelet/pods"
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "k0s kubectl drain --ignore-daemonsets --delete-emptydir-data ${self.triggers.name} || true",
      "k0s etcd leave ${self.triggers.name} || true"
    ]
  }
}
