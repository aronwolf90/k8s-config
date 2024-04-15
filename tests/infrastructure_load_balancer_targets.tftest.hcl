provider "hcloud" {
  token = "123456789_123456789_123456789_123456789_123456789_123456789_1234"
}

variables {
  private_ssh_key_path = "tests/fixtures/ssh_host_first_key.pub"

  nodes = {
    node1 = {
      image       = "ubuntu-22.04",
      location    = "fsn1",
      server_type = "cx21",
      role        = "controller"
    }
    node2 = {
      image       = "ubuntu-22.04"
      location    = "fsn1"
      server_type = "cx21"
      role        = "controller+worker"
    }
    node3 = {
      image       = "ubuntu-22.04"
      location    = "fsn1"
      server_type = "cx21"
      role        = "worker"
    }
  }
}

run "module_infrastructure_hcloud_load_balancer_target" {
  command = plan

  module {
    source = "./infrastructure"
  }

  assert {
    condition     = length(hcloud_load_balancer_target.controller) == 2
    error_message = "Wrong number of hcloud_load_balancer_targets"
  }
}
