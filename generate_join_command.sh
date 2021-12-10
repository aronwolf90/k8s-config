#!/bin/bash

counter=0

until timeout 5 ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null root@"$MAIN_MASTER_IP" "kubectl get nodes" 1> /dev/null
do
  sleep 1
  counter=$((counter + 1))

  if [ $counter -eq 600 ]; then
    exit 1
  fi
done

# shellcheck disable=SC2128
ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null root@"$MAIN_MASTER_IP" \
  'echo "$(kubeadm token create --ttl 0 --print-join-command) --certificate-key $(kubeadm init phase upload-certs --upload-certs | tail -n1) --control-plane"' > "$(dirname "$BASH_SOURCE")"/master_join_command.txt
