#!/bin/bash

set -x

export OS_CLOUD=ECP-nbock

: ${OSH_HOSTNAME:=nbock-osh}
: ${OSH_IMAGE:=ubuntu-16.04-server-cloudimg-amd64-disk1.img}
: ${OSH_FLAVOR:=m2.xlarge}

if openstack server show ${OSH_HOSTNAME} > /dev/null; then
  echo "the server '${OSH_HOSTNAME}' already exists"
  openstack server rebuild --image ${OSH_IMAGE} ${OSH_HOSTNAME}
else
  openstack server create \
    --flavor ${OSH_FLAVOR} \
    --image ${OSH_IMAGE} \
    --network fixed \
    --security-group default \
    --security-group ping/ssh \
    --key-name nbock \
    ${OSH_HOSTNAME}
fi

while true; do
  OSH_VM_PORT=$(openstack port list \
    --format value \
    --column ID \
    --server ${OSH_HOSTNAME})
  if (( $? == 0 )); then
    break
  fi
done

OSH_VM_FIP=$(openstack floating ip list \
  --port ${OSH_VM_PORT} \
  --format value \
  --column "Floating IP Address")

if [[ -z ${OSH_VM_FIP} ]]; then
  openstack floating ip create \
    --port ${OSH_VM_PORT} \
    floating

  OSH_VM_FIP=$(openstack floating ip list \
    --column 'Floating IP Address' \
    --format value \
    --port ${OSH_VM_PORT})
fi

ssh-keygen -R ${OSH_VM_FIP}
