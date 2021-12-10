#!/bin/bash

set -e

sudo sed -i '/ swap / s/^/#/' /etc/fstab
swapoff -a

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

apt-get update && sudo apt-get install -y apt-transport-https curl docker.io jq etcd-client
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl enable docker.service
systemctl daemon-reload
systemctl restart docker

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
modprobe br_netfilter
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-mark unhold kubelet kubeadm kubectl || true
sudo apt-get install -y \
  kubelet="$KUBERNETES_VERSION-00" \
  kubeadm="$KUBERNETES_VERSION-00" \
  kubectl="$KUBERNETES_VERSION-00" || true
sudo apt-mark hold kubelet kubeadm kubectl || true

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/20-hcloud.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
EOF
