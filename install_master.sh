#!/bin/bash

set -e

if [ ! -f /etc/kubernetes/pki/ca.crt ]; then
  if [ -z "$MASTER_JOIN_COMMAND" ]; then
    kubeadm init --pod-network-cidr=10.244.0.0/16 \
      --control-plane-endpoint "$LOAD_BALANCER_IP:6443" \
      --ignore-preflight-errors=DirAvailable--var-lib-etcd \
      --kubernetes-version "$KUBERNETES_VERSION"
  else
    # shellcheck disable=SC2086
    $MASTER_JOIN_COMMAND
  fi
else
  sleep 60

  kubeadm upgrade apply "v$KUBERNETES_VERSION" -y
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
fi

sed -e "s/- --bind-address=127.0.0.1/- --bind-address=0.0.0.0/" -i /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -e "s/- --bind-address=127.0.0.1/- --bind-address=0.0.0.0/" -i /etc/kubernetes/manifests/kube-scheduler.yaml

mkdir -p "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"
kubectl apply -f /tmp/token.yaml
