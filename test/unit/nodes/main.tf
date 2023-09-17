terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

locals {
  kubeconfig = file("./config")
}

provider "hcloud" {
  token = var.hcloud_token
}
