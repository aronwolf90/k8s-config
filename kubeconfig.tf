resource "local_file" "kubeconfig" {
  content  = local.kubeconfig
  filename = "${path.module}/tmp/kubeconfig"
}
