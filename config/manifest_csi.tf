locals {
  # TODO: Upgrade after dropping support for k8s v1.22
  hcloud_csi_file_path = "${path.module}/hetzner_manifests/hcloud-csi-1.6.0.yaml"
}

resource "null_resource" "hcloud_csi" {
  triggers = {
    file_md5 = md5(file(local.hcloud_csi_file_path))
  }

  provisioner "local-exec" {
    command = <<-EOT
cat <<EOF > ${path.module}/tmp/kubeconfig
${var.kubeconfig}
EOF
EOT
  }

  provisioner "local-exec" {
    command = "${local.kubectl} --kubeconfig=\"${path.module}/tmp/kubeconfig\" apply -f ${local.hcloud_csi_file_path}"
  }
}
