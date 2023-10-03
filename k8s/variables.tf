variable "nodes" {
  type = list(
    object({
      name = string
      ipv4 = string
      role = string
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
