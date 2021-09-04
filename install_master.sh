#!/bin/bash

set -e

bash /tmp/install_kubedm.sh

kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint $LOAD_BALANCER_IP:6443 \
  --ignore-preflight-errors=DirAvailable--var-lib-etcd \
  --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml \
  --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-kube-controller-manager.yaml \
  --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-kube-scheduler.yaml \
  --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-etcd.yaml \

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
kubectl create secret generic hcloud-csi -n kube-system --from-literal=token=$HCLOUD_TOKEN
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.5.3/deploy/kubernetes/hcloud-csi.yml
bash /tmp/install_cluster_autoscaler.sh
