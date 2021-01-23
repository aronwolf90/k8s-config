#!/usr/bin/env sh

set -e

jq --version >/dev/null 2>&1 || apt-get install jq -y >/dev/null 2>&1

# Extract "host" and "key_file" argument from the input into HOST shell variable
eval "$(jq -r '@sh "HOST=\(.host) KEY=\(.key)"')"

# Certificate
CERTIFICATE=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY \
    root@$HOST kubeadm init phase upload-certs --upload-certs | tail -n1)

# Fetch the join command
CMD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY \
    root@$HOST kubeadm token create --print-join-command --certificate-key $CERTIFICATE)

# Produce a JSON object containing the join command
jq -n --arg command "$CMD --control-plane" '{"command":$command}'
