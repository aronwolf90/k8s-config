#!/usr/bin/bash

mkdir -p /var/lib/etcd
docker run --rm \
  -v '/backups:/backups' \
  -v '/var/lib/etcd:/var/lib/etcd' \
  --env ETCDCTL_API=3 \
  k8s.gcr.io/etcd:3.2.24 \
  /bin/sh -c "etcdctl snapshot restore '$(ls -1t /backups/*db | tail -1)' ; mv /default.etcd/member/ /var/lib/etcd/"
