#!/bin/bash

set -e

sudo sed -i '/ swap / s/^/#/' /etc/fstab
swapoff -a

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

apt-get update && sudo apt-get install -y \
  apt-transport-https \
  curl \
  ca-certificates \
  gnupg \
  jq \
  etcd-client \
  lsb-release

if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get upgrade -y
apt-mark unhold kubelet kubeadm kubectl || true
apt-get install -y \
  containerd.io \
  kubelet="$KUBERNETES_VERSION-00" \
  kubeadm="$KUBERNETES_VERSION-00" \
  kubectl="$KUBERNETES_VERSION-00"
sudo apt-mark hold kubelet kubeadm kubectl || true

cat << EOF | sudo tee /etc/modules-load.d/containerd.conf 
overlay 
br_netfilter 
EOF
modprobe br_netfilter
modprobe overlay
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
systemctl enable containerd
systemctl daemon-reload
systemctl restart containerd

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/20-hcloud.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
EOF
