resource "null_resource" "hcloud_csi" {
  triggers = {
    file_md5 = md5(file("${path.module}/hetzner_manifests/hcloud-csi-2.4.0.yaml")) 
  }

  provisioner "local-exec" {
    command = <<-EOT
cat <<EOF > ${path.module}/tmp/kubeconfig
${var.kubeconfig}
EOF
EOT
  }

  provisioner "local-exec" {
    command = "${local.kubectl} --kubeconfig=\"${path.module}/tmp/kubeconfig\" apply -f ${path.module}/hetzner_manifests/hcloud-csi-2.4.0.yaml"
  }
}
