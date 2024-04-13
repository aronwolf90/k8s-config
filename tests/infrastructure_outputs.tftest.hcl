provider "hcloud" {
  token = "123456789_123456789_123456789_123456789_123456789_123456789_1234"
}

variables {
  private_ssh_key_path = "~/.ssh/id_rsa"
  
  nodes = {
    "node" = {
      image = "ubuntu-22.04",
      location = "fsn1",
      server_type = "cx21",
      role = "controller+worker"
    },
  }
}

run "infrastructure_outputs_nodes_ipv4" {
  command = plan

  module {
    source = "./infrastructure"
  }

  assert {
    condition =  contains(keys(output.nodes.node), "ipv4")
    error_message = "The nodes do not contain an ip"
  }
}
