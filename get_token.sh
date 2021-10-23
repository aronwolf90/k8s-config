#!/bin/bash

set -e

TOKEN=$(ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null root@"$MASTER_IP" "kubectl -n kube-system get secret \$(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}') -o=jsonpath='{.data.token}'" | base64 --decode)

echo -n "{\"token\": \"$TOKEN\"}"
