#!/bin/bash

set -e

SERVER_IDS=$(
  kubectl get nodes -o json |
  jq -r '[.items[] | select(.metadata.name != "master")]' |
  jq -r '.[].metadata.annotations."csi.volume.kubernetes.io/nodeid"' |
  sed 's/[^0-9]*//g'
)

for ID in $SERVER_IDS; do
  curl -X DELETE -H "Authorization: Bearer $HCLOUD_TOKEN" "https://api.hetzner.cloud/v1/servers/$ID"
done
