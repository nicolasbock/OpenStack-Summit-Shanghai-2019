#!/bin/bash

set -x -e

STEPS=(
  ./tools/deployment/developer/common/010-deploy-k8s.sh
  ./tools/deployment/developer/common/020-setup-client.sh
  ./tools/deployment/developer/common/030-ingress.sh
  ./tools/deployment/developer/nfs/040-nfs-provisioner.sh
  ./tools/deployment/developer/nfs/050-mariadb.sh
  ./tools/deployment/developer/nfs/060-rabbitmq.sh
  ./tools/deployment/developer/nfs/070-memcached.sh
  ./tools/deployment/developer/nfs/080-keystone.sh
  ./tools/deployment/developer/nfs/090-heat.sh
  ./tools/deployment/developer/nfs/100-horizon.sh
  ./tools/deployment/developer/nfs/120-glance.sh
  ./tools/deployment/developer/nfs/140-openvswitch.sh
  ./tools/deployment/developer/nfs/150-libvirt.sh
  ./tools/deployment/developer/nfs/160-compute-kit.sh
  ./tools/deployment/developer/nfs/170-setup-gateway.sh
  ./tools/deployment/developer/common/900-use-it.sh
)

if (( $# < 1 )); then
  echo "missing IP address for OSH host"
  exit 1
fi

OSH_IP=$1

for step in "${STEPS[@]}"; do
  result=$(ssh ubuntu@${OSH_IP} "cd openstack-helm && ${step}")
  if (( ${result} != 0 )); then
    echo "remote command ${step} failed with ${result}"
    exit 1
  fi
done
