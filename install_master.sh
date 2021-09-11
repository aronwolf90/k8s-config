#!/bin/bash

set -e

bash /tmp/install_kubedm.sh

if [ ! -f /etc/kubernetes/pki/ca.crt ]; then
  if [ -f /backups/ca.crt ]; then
    mkdir -p /var/lib/etcd
    mkdir -p /etc/kubernetes/pki/
  
    cp /backups/ca.crt /etc/kubernetes/pki/ca.crt 
    cp /backups/ca.key /etc/kubernetes/pki/ca.key 
  
    docker run --rm \
      -v '/backups:/backups' \
      -v '/var/lib/etcd:/default.etcd/' \
      --env ETCDCTL_API=3 \
      k8s.gcr.io/etcd:3.5.0-0 \
      /bin/sh -c "etcdctl snapshot restore '$(ls -1t /backups/*db | tail -1)'"
  fi
  
  kubeadm init --pod-network-cidr=10.244.0.0/16 \
    --control-plane-endpoint $LOAD_BALANCER_IP:6443 \
    --ignore-preflight-errors=DirAvailable--var-lib-etcd \
    --kubernetes-version $KUBERNETES_VERSION
else
  sleep 60
fi

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
kubectl -n kube-system patch ds kube-flannel-ds --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'
kubectl get secret  hcloud-csi -n kube-system ||
  kubectl create secret generic hcloud-csi -n kube-system --from-literal=token=$HCLOUD_TOKEN
kubectl get secret  hcloud -n kube-system ||
  kubectl create secret generic hcloud -n kube-system --from-literal=token=$HCLOUD_TOKEN
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.6.0/deploy/kubernetes/hcloud-csi.yml
bash /tmp/hcloud.sh
kubectl apply -f /tmp/token.yaml
bash /tmp/install_cluster_autoscaler.sh
