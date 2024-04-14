# Hetzner cluster

It is a terraform module that allow to deploy a k0s based cluster on hetzner easily:

It supports the following features:
- Setup a full working k8s in a few minutes.
- Upgrade the k8s version by just changing the version number.
- Volumes (using Hetzner volumes)
- Load balancers (Using Hetzner load balancers)

## Purpose of this cluster
This cluster is thought for personal projects and small companies that need HA. This traduces in:
- Using Hetzner because it is very cheap.
- Make it possible to use the same nodes for controllers and workers.

## Usage
Add to your tofu file the following:
```bash
module "cluster" {             
  source = "git::https://gitlab.com/webcloudpower/hetzner_cluster.git?ref=0.8.3"
    
  hcloud_token = "MY_HETZNER_TOKEN"
}
```

Or if you want to avoid default values, use this:
```bash
module "cluster" {             
  source = "git::https://gitlab.com/webcloudpower/hetzner_cluster.git?ref=0.8.3"
    
  hcloud_token         = "MY_HETZNER_TOKEN"
  k0s_version          = "v1.21.14+k0s.0"
  private_ssh_key_path = "~/.ssh/id_rsa" 
  drain_timeout        = 40 # seconds
  public_ssh_keys      = [
    { name = "default", key = file("~/.ssh/id_rsa.pub") }
  ]

  nodes = {
    "controller1" = { image = "ubuntu-22.04", location = "fsn1", server_type = "cx21", role = "controller+worker" },
    "controller2" = { image = "ubuntu-22.04", location = "fsn1", server_type = "cx21", role = "controller+worker" },
    "controller3" = { image = "ubuntu-22.04", location = "fsn1", server_type = "cx21", role = "controller+worker" },
  }
}
```

The module assumes that you have your public key in `~/.ssh/id_rsa.pub`. Once you have
adjusted your terraform file, you just have to run `tofu apply`.

## Outputs
* `host`
* `cluster_ca_certificate`
* `client_certificate`
* `client_key`
* `hcloud_token`

## Default costs
* 3 controller+worker nodes (CX21): 3 * 2CPU and 3 * 4GB -> 3 * 5,83 EUR = 16,49 EUR
* Load balancer (LB11) -> 5,83 EUR

This is at the moment of writing 22,32 EUR per month.

NOTE: Comparing to GCloud, it is 3 times cheaper for the first cluster and 5 times cheaper for the second cluster (For the first cluster GCloud does not charge for the master node).

NOTE: A load balancer is used for the api to allow easier disaster recovery.

## Upgrade
Just change `k0s_version` to the desired version and run `tofu apply`.

## Tested against
* v1.21.14+k0s.0 
* v1.22.17+k0s.0
* v1.23.17+k0s.1
* v1.24.17+k0s.0
* v1.25.14+k0s.0
* v1.26.9+k0s.0
* v1.27.6+k0s.0
* v1.28.2+k0s.0

# Test
- Create a `tests/e2e/terraform.tfvars` file with the following content:
  ```
  hcloud_token = <token>
  ```
- Execute: `asdf install`
- Execute:
  * For integration test: `cd tests/e2e && go test -timeout 99999s"`.
  * For testing all supported K8s versions `cd tests/e2e && TEST_K8S_VERSIONS=true go test -timeout 99999s`
  * For unit test: `tofu test`.

# TODOs
* Remove the need to have an installed `kubectl`. 
* Add auto scaling (Do we really need it?).
