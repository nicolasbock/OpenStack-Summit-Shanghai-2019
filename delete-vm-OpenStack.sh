#!/bin/bash

set -x

export OS_CLOUD=ECP-nbock

: ${OSH_HOSTNAME:=nbock-osh}

OSH_VM_PORT=$(openstack port list \
  --format value \
  --column ID \
  --server ${OSH_HOSTNAME})

OSH_VM_FIP=$(openstack floating ip list \
  --column 'Floating IP Address' \
  --format value \
  --port ${OSH_VM_PORT})

openstack floating ip delete ${OSH_VM_FIP}
openstack server delete ${OSH_HOSTNAME}
