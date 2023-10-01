resource "null_resource" "hcloud_secret" {
  provisioner "local-exec" {
    command = <<-EOT
cat <<EOF > ${path.module}/tmp/kubeconfig
${var.kubeconfig}
EOF
EOT
  }

  provisioner "local-exec" {
    command = "${local.kubectl} --kubeconfig=\"${path.module}/tmp/kubeconfig\" create secret generic hcloud --from-literal=\"token=${var.hcloud_token}\" -n kube-system "
  }
}
