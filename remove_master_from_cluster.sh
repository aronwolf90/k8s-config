#!/bin/bash

set -e

export ETCDCTL_API=3

IDS=$(
  etcdctl -w json member list \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key | \
  sed 's/\("ID":\)\([0-9]\+\)\(,\)/\1"\2"\3/g' | \
  jq ".members[] | .ID"
)

[[ $(echo "$IDS" | wc -l) == 1 ]] && exit 0

ID=$(
  etcdctl -w json member list \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key | \
  sed 's/\("ID":\)\([0-9]\+\)\(,\)/\1"\2"\3/g' | \
  jq ".members[] | select(.name|test(\"^$NAME$\")) | .ID"
)

etcdctl member remove "$(printf '%x' "$(bc <<< "$ID")")" \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key || true
