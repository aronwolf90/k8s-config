#!/bin/bash

set -e

# shellcheck disable=SC2153
for MASTER_IP in $MASTER_IPS; do
  if timeout 5 ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null root@"$MASTER_IP" "kubectl get nodes" 1> /dev/null ; then
    # shellcheck disable=SC2016
    COMMAND=$(ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null root@"$MASTER_IP" \
      'echo "$(kubeadm token create --ttl 0 --print-join-command) --certificate-key $(kubeadm init phase upload-certs --upload-certs | tail -n1) --control-plane"')
    break
  fi
done

echo -n "{\"command\": \"$COMMAND\"}"
