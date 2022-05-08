#!/bin/bash

set -e

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.18.0/Documentation/kube-flannel.yml
kubectl -n kube-system patch ds kube-flannel-ds --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'
kubectl get secret  hcloud-csi -n kube-system ||
  kubectl create secret generic hcloud-csi -n kube-system --from-literal=token="$HCLOUD_TOKEN"
kubectl get secret  hcloud -n kube-system ||
  kubectl create secret generic hcloud -n kube-system --from-literal=token="$HCLOUD_TOKEN"
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.6.0/deploy/kubernetes/hcloud-csi.yml
bash /tmp/hcloud.sh
kubectl apply -f /tmp/token.yaml
bash /tmp/install_cluster_autoscaler.sh
