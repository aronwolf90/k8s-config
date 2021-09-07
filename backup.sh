#!/usr/bin/bash

mkdir -p backups

ssh root@$1 <<EOF
docker run --rm \
  -v '/tmp:/tmp' \
  -v '/var/lib/etcd:/var/lib/etcd' \
  -v '/etc/kubernetes:/etc/kubernetes' \
  --env ETCDCTL_API=3 \
  --network host \
  k8s.gcr.io/etcd:3.5.0-0 \
  etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key=/etc/kubernetes/pki/etcd/healthcheck-client.key snapshot save /tmp/etcd-snapshot.db
EOF

scp root@$1:/tmp/etcd-snapshot.db backups
scp root@$1:/etc/kubernetes/pki/ca.crt backups
scp root@$1:/etc/kubernetes/pki/ca.key backups
