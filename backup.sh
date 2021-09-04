#!/usr/bin/bash

docker run --rm \
  -v '/backups:/backups' \
  -v '/var/lib/etcd:/var/lib/etcd' \
  -v '/etc/kubernetes:/etc/kubernetes' \
  --env ETCDCTL_API=3 \
  --network host \
  k8s.gcr.io/etcd:3.2.24 \
  etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key=/etc/kubernetes/pki/etcd/healthcheck-client.key snapshot save /backups/etcd-snapshot-$(date +%Y-%m-%d_%H:%M:%S_%Z).db
