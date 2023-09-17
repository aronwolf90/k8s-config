resource "null_resource" "ccm-networks" {
  triggers = {
    file_md5 = md5(file("${path.module}/hetzner_manifests/ccm-v1.12.1.yaml")) 
  }

  provisioner "local-exec" {
    command = <<-EOT
cat <<EOF > ${path.module}/tmp/kubeconfig
${var.kubeconfig}
EOF
EOT
  }

  provisioner "local-exec" {
    command = "${local.kubectl} --kubeconfig=\"${path.module}/tmp/kubeconfig\" apply -f ${path.module}/hetzner_manifests/ccm-v1.12.1.yaml"
  }
}
