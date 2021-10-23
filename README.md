# Hetzner cluster

It is a terraform module that allow to deploy a kubedm based clsuter on hetzner in a easy way:

It support the following features:
- Setup a full working k8s in a few minutes.
- Autostaling of worker nodes.
- Backup and restore the cluster.
- Upgrade the k8s version by just chaning the version number.
- Volumes (using Hetzner volumes)
- Loadbalancers (USings Hetzner load balancers)

## Porpuse of this cluster
This cluster is thought for personal projects and small companies. This traduces in:
- Using hetzner because it is very cheap.
- Use one master instead of many and let stuff like etcd on the master node.
- Not support multi zone clusters. For small to medium project it is most of the times enough to have backups or wait that the
  hardware failure (that happen very very unfrecuently) is fixed by hetzner instead of paying for more redundancy.

NOTE: If you need any of the not supported features you can allways submit a pull request.

## Usage
Add to your terraform file the following:
```bash
module "cluster" {             
  source = "git::https://gitlab.com/webcloudpower/hetzner_cluster.git?ref=0.1.0"
    
  hcloud_token       = "MY_HETZNER_TOKEN"
  kubernetes_version = "1.19.15"  
}
```

The module assumes that you have your public key in `~/.ssh/id_rsa.pub`. Once you have adjusted your terraform file you just have to run `terraform apply`.

## Min costs
Master node (CX21): 2CPU and 4GB -> 5,83 EUR
Worker node (CPX11): 2CPU and 2GB -> 4,75 EUR
Load balancer (LB11) -> 5,83 EUR

This is at the moment of writing this 16,41 EUR per month.

NOTE: Comparing to GCloud it is 3 times cheaper for the first cluster and 5 times cheaper for the second cluster (For the first cluster GCloud does not charge for the master node).
NOTE: A load balancer is used for the api to allow easier disaster recovery.

## Upgrade
Just change `kubernetes_version` to the desired version and run `terraform apply`.

NOTE: A backup is created in the local folder `backups/`. To restore the backup go to `.terraform/modules/cluster/` and run `bash restore.sh <master_ip>`. If it is absolutely necessary the master node can be taint before restoring the backup.
