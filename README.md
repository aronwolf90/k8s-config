# Hetzner cluster

It is a terraform module that allow to deploy a kubedm based cluster on hetzner easily:

It supports the following features:
- Setup a full working k8s in a few minutes.
- Autostaling of worker nodes.
- Upgrade the k8s version by just chaning the version number.
- Volumes (using Hetzner volumes)
- Loadbalancers (USings Hetzner load balancers)

## Porpuse of this cluster
This cluster is thought for personal projects and small companies. This traduces in:
- Using hetzner because it is very cheap.
- Use one master instead of many and let stuff like etcd on the master node.
- Not support multi zone clusters. For small to medium project it is most of the time enough to have backups or wait that the
  hardware failure (that happen very unfrecuently) is fixed by hetzner instead of paying for more redundancy.

NOTE: If you need any of the not supported features you can allways submit a pull request.

## Usage
Add to your terraform file the following:
```bash
module "cluster" {             
  source = "git::https://gitlab.com/webcloudpower/hetzner_cluster.git?ref=0.2.0"
    
  hcloud_token       = "MY_HETZNER_TOKEN"
  kubernetes_version = "1.19.15"  
  location           = "fsn1" 
  main_master_name   = "master" 
  master_nodes       = [ 
    { name = "master",  image="ubuntu-20.04" }
  ]
}
```

The module assumes that you have your public key in `~/.ssh/id_rsa.pub`. Once you have adjusted your terraform file, you just have to run `terraform apply`.

## Outputs
* `token`: A token that can be used to access the k8s api.
* `host`: Api url. 
* `master_nodes`: Configuration of the master nodes.
  * `ip4`: The ip4 address of the master node

## Min costs
* Master node (CX21): 2CPU and 4GB -> 5,83 EUR
* Worker node (CPX11): 2CPU and 2GB -> 4,75 EUR
* Load balancer (LB11) -> 5,83 EUR

This is at the moment of writing 16,41 EUR per month.

NOTE: Comparing to GCloud, it is 3 times cheaper for the first cluster and 5 times cheaper for the second cluster (For the first cluster GCloud does not charge for the master node).

NOTE: A load balancer is used for the api to allow easier disaster recovery.

## Upgrade
Just change `kubernetes_version` to the desired version and run `terraform apply`.

## Replace master node.
It can happen that you need to replace the master nodes. One cause can be that you want to replace the node operation system
(it can be done by changing `masters=[{name = "master", image="<image>" }]`). The problem is that
the data is stored in the master nodes, so that this could leave to lose all of your k8s configurations.
The solution to this is to replace one per one master node instead of replacing all of them at the same time.

In the case that you use more than one master node, do the following:
- Recreate the master node (E.g. change his image).
  ```bash
  masters = [
    {name = "master1", image="<new image>" },
    ...
  ]
  ```
- Wait that the recreted master is syncronized with the rest of master nodes.
- Repeat the same with the other master nodes.

In case that you are only using one master node to save money, do the following:
- You need to scale up to two master nodes. For this adjust the variable `masters`.
  ```bash
  masters=[
    {name = "master",  image="<image>" },
    {name = "master_v2", image="<new image>" }
  ]
  main_master_name = "master"
  ```
- Wait some time until the two master have syncronized, then set the new master to main_master_name and remove the old master.
  ```bash
  masters=[
    {name = "master_v2", image="<image>" }
  ]
  main_master_name = master_v2
  ```

NOTE: Do not forget to make a backup before doing the above.

NOTE: Feel free to create a MR that reduce all of this to one only step.
(E.g. by using create_before_destroy).

# Contribute
- Execute `git clone git@gitlab.com:webcloudpower/hetzner_cluster.git`.
- Create a `terraform.tfvars` file with the following content:
  ```
  hcloud_token = <token>
  ```

You can now test you changes with `terraform apply` or `docker-compose run --rm app go test -timeout=9999s`
