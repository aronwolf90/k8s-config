locals {
  ccm_networks_file_path = "${path.module}/hetzner_manifests/ccm-v1.12.1.yaml"
}

resource "null_resource" "ccm-networks" {
  triggers = {
    file_md5 = md5(file(local.ccm_networks_file_path)) 
  }

  provisioner "local-exec" {
    command = <<-EOT
cat <<EOF > ${path.module}/tmp/kubeconfig
${var.kubeconfig}
EOF
EOT
  }

  provisioner "local-exec" {
    command = "${local.kubectl} --kubeconfig=\"${path.module}/tmp/kubeconfig\" apply -f ${local.ccm_networks_file_path}"
  }
}
