#!/bin/bash

set -e

# shellcheck disable=SC2153
for MASTER_IP in $MASTER_IPS; do
  if timeout 5 ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null root@"$MASTER_IP" "kubectl get nodes" 1> /dev/null ; then
    TOKEN=$(ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null root@"$MASTER_IP" "kubectl -n kube-system get secret \$(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}') -o=jsonpath='{.data.token}'" | base64 --decode)
    break
  fi
done
  
echo -n "{\"token\": \"$TOKEN\"}"
