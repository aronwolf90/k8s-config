variable "public_ssh_keys" {
  type = list(
    object({
      name = string
      key  = string
    })
  )

  default = null
}

variable "private_ssh_key_path" {}

variable "nodes" {
  type = map(
    object({
      image       = string
      location    = string
      server_type = string
      role        = string
    })
  )
}
