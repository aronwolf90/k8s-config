variable "hcloud_token" {}

variable "kubernetes_version" {
  default = "1.19.16"
}

variable "master_load_balancer_location" {
  default = "fsn1"
}

variable "master_nodes" {
  type = list(
    object({
      name     = string
      image    = string
      location = string
    })
  )

  default = [
    { name = "master", image = "ubuntu-20.04", location = "fsn1" },
  ]
}

variable "main_master_name" {
  default = "master"
}

variable "worker_node_type" {
  default = "CPX21"
}

variable "worker_node_location" {
  default = "fsn1"
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
