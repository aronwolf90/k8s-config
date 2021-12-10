#!/bin/bash

set -e

kubectl delete deployment cluster-autoscaler -n kube-system || true

NUMBER_PAGES=$(curl -X GET -H "Authorization: Bearer $HCLOUD_TOKEN" https://api.hetzner.cloud/v1/servers | jq ".meta.pagination.last_page")

for PAGE in $(seq 1 "$NUMBER_PAGES"); do
  for ID in $(curl -X GET -H "Authorization: Bearer $HCLOUD_TOKEN" "https://api.hetzner.cloud/v1/servers?page=$PAGE" | jq '.servers[] | select(.name|test("pool")) | .id'); do
    curl -X DELETE -H "Authorization: Bearer $HCLOUD_TOKEN" "https://api.hetzner.cloud/v1/servers/$ID" || true
  done
done
