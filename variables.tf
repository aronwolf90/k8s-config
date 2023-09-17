variable "hcloud_token" {}

variable "k0s_version" {
  default = "v1.21.14+k0s.0"
}

# When no public key is specifed, it uses "/.ssh/id_rsa.pub"
# For more details see `locals.tf`.
variable "public_ssh_keys" {
  type = list(
    object({
      name = string
      key  = string
    })
  )

  default = null
}

variable "private_ssh_key_path" {
  type = string

  default = "~/.ssh/id_rsa"
}

variable "nodes" {
  type = list(
    object({
      name        = string
      image       = string
      location    = string
      server_type = string
      role        = string
    })
  )

  default = [
    { name = "controller1", image = "ubuntu-22.04", location = "fsn1", server_type = "cx21", role = "controller+worker" },
    { name = "controller2", image = "ubuntu-22.04", location = "fsn1", server_type = "cx21", role = "controller+worker" },
    { name = "controller3", image = "ubuntu-22.04", location = "fsn1", server_type = "cx21", role = "controller+worker" },
  ]
}
