#!/bin/bash

set -e

function ssh_command {
  timeout 5 ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -i "$PRIVATE_KEY" root@"$1" "$2"
}

# shellcheck disable=SC2153
for MASTER_IP in $MASTER_IPS; do
  if ssh_command "$MASTER_IP" "kubectl get nodes" 1> /dev/null ; then
    TOKEN=$(ssh_command "$MASTER_IP" "kubectl -n kube-system get secret \$(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}') -o=jsonpath='{.data.token}'")
    CLUSTER_CA_CERTIFICATE=$(ssh_command "$MASTER_IP" "cat /etc/kubernetes/pki/ca.crt" | base64 -w 0)
    break
  fi
done


cat <<EOF
{
  "token": "$TOKEN",
  "cluster_ca_certificate": "$CLUSTER_CA_CERTIFICATE"
}
EOF
