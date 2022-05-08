#!/bin/bash

set -e

kubectl drain "$NAME" --delete-local-data --ignore-daemonsets --force
sleep 30
kubectl delete node "$NAME"
curl -X DELETE -H "Authorization: Bearer $HCLOUD_TOKEN" "https://api.hetzner.cloud/v1/servers/$ID"
