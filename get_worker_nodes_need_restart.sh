#!/bin/bash

set -e

kubectl get nodes -o json |
  jq -r "[.items[] | select((.metadata.labels.\"beta.kubernetes.io/instance-type\" != \"$(echo "$WORKER_SERVER_TYPE" | tr "[:upper:]" "[:lower:]")\" or .status.nodeInfo.kubeletVersion != \"v$KUBERNETES_VERSION\") and (.metadata.name|test(\"pool.*\")))]" | jq -r '[.[] | {name: .metadata.name, id: (.metadata.annotations."csi.volume.kubernetes.io/nodeid" | fromjson | ."csi.hetzner.cloud")}]'
