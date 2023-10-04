variable "nodes" {
  type = map(
    object({
      role = string
      ipv4 = string
    })
  )
}

variable "load_balancer_ipv4" {
  type = string
}

variable "private_ssh_key_path" {
  type = string
}

variable "k0s_version" {
  type = string
}
