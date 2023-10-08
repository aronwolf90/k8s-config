resource "null_resource" "nodes" {
  for_each = var.nodes

  depends_on = [k0s_cluster.cluster]

  triggers = {
    ipv4 = each.value.ipv4
    name = each.key
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
      "ln -sf /var/lib/k0s/kubelet/ /var/lib/kubelet"
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "#!/bin/bash",
      "[[ $(k0s kubectl get nodes | grep -v SchedulingDisabled | wc -l) -le 2 ]] && exit 0",
      "k0s kubectl drain --ignore-daemonsets --delete-emptydir-data ${self.triggers.name} || true",
      "k0s kubectl delete node ${self.triggers.name} || true",
      "k0s etcd leave ${self.triggers.name} || true"
    ]
  }
}
