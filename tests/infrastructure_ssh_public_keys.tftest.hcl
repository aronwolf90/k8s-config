provider "hcloud" {
  token = "123456789_123456789_123456789_123456789_123456789_123456789_1234"
}

variables {
  private_ssh_key_path = "~/.ssh/id_rsa"
  public_ssh_keys = [
    {
      name = "first"
      key  = "tests/unit/fixtures/ssh_host_first_key.pub",
    },
    {
      name = "second"
      key  = "tests/unit/fixtures/ssh_host_second_key.pub"
    }
  ]

  nodes = {
    node = {
      image       = "ubuntu-22.04",
      location    = "fsn1",
      server_type = "cx21",
      role        = "controller"
    }
  }
}

run "infrastructure_ssh_public_keys" {
  command = plan

  module {
    source = "./infrastructure"
  }

  assert {
    condition =  length(hcloud_ssh_key.ssh_public_keys) == 2
    error_message = "Not correct ssh keys"
  }
}
