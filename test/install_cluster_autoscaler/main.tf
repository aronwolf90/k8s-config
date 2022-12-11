output "template" {
  value = templatefile(
    "${path.module}/install_cluster_autoscaler.sh.tftpl",
    { node_pools = var.node_pools }
  )
}
