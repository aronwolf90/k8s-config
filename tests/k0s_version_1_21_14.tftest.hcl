variables {
  load_balancer_ipv4   = "100.100.100.01"
  private_ssh_key_path = "tests/fixtures/ssh_host_first_key"
  k0s_version          = "v1.21.14+k0s.0"
  drain_timeout        = 40
  nodes = {
    node1 = {
      ipv4 = "100.100.100.02",
      role = "controller"
    }
    node2 = {
      ipv4 = "100.100.100.03",
      role = "controller+worker"
    }
    node3 = {
      ipv4 = "100.100.100.04",
      role = "worker"
    }
  }
}

run "module_infrastructure_v1_21_14" {
  command = plan

  module {
    source = "./k8s"
  }

  assert {
    condition = tolist(k0s_cluster.cluster.hosts)[0].no_taints == null
    error_message = "Wrong number of hcloud_load_balancer_targets"
  }
}
