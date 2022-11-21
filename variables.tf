variable "hcloud_token" {}

variable "location" {
  default = "hel1"
}

variable "kubernetes_version" {
  default = "1.19.16"
}

variable "master_nodes" {
  type = list(
    object({
      name  = string
      image = string
    })
  )

  default = [
    { name = "master", image = "ubuntu-20.04" },
  ]
}

variable "main_master_name" {
  default = "master"
}

variable "worker_node_type" {
  default = "CPX21"
}

variable "ssh_public_keys" {
  type = list(
    object({
      name  = string
      key = string
    })
  )

  default = null
}

variable "worker_public_ssh_key" {
  type = string

  default = null
}

variable "private_key" {
  default = "~/.ssh/id_rsa"
}
