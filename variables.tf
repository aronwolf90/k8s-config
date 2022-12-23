variable "hcloud_token" {}

variable "kubernetes_version" {
  default = "1.21.14"
}

variable "master_load_balancer_location" {
  default = "fsn1"
}

variable "load_balancer_location" {
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
  type = string

  default = "~/.ssh/id_rsa"
}

variable "node_pools" {
  type = list(
    object({
      name      = string
      node_type = string
      location  = string
    })
  )
  
  default = [{ name = "pool", node_type = "CPX21", location = "fsn1" }]
}
