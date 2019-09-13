# Deploy OpenStack Helm

## Create instance with libvirt

    $ ./create-vm-libvirt.sh
    $ ansible-playbook --inventory 192.168.122.149, prepare-osh-host.yml

## Gate commands

    $ ./tools/deployment/common/install-packages.sh
    $ ./tools/deployment/common/deploy-k8s.sh
    $ ./tools/deployment/common/setup-client.sh
    $ ./tools/deployment/component/common/ingress.sh
    $ ./tools/deployment/component/common/mariadb.sh
    $ ./tools/deployment/component/common/memcached.sh
    $ ./tools/deployment/component/common/rabbitmq.sh
    $ ./tools/deployment/component/nfs-provisioner/nfs-provisioner.sh
    $ ./tools/deployment/component/keystone/keystone.sh
    $ ./tools/deployment/component/heat/heat.sh
    $ ./tools/deployment/component/glance/glance.sh
    $ ./tools/deployment/component/compute-kit/openvswitch.sh
    $ ./tools/deployment/component/compute-kit/libvirt.sh
    $ ./tools/deployment/component/compute-kit/compute-kit.sh
    $ ./tools/deployment/developer/common/170-setup-gateway.sh
    $ ./tools/deployment/developer/common/900-use-it.sh

## Developer commands

    $ ./tools/deployment/developer/common/010-deploy-k8s.sh
    $ ./tools/deployment/developer/common/020-setup-client.sh
    $ ./tools/deployment/developer/common/030-ingress.sh
    $ ./tools/deployment/developer/nfs/040-nfs-provisioner.sh
    $ ./tools/deployment/developer/nfs/050-mariadb.sh
    $ ./tools/deployment/developer/nfs/060-rabbitmq.sh
    $ ./tools/deployment/developer/nfs/070-memcached.sh
    $ ./tools/deployment/developer/nfs/080-keystone.sh
    $ ./tools/deployment/developer/nfs/090-heat.sh
    $ ./tools/deployment/developer/nfs/100-horizon.sh
    $ ./tools/deployment/developer/nfs/120-glance.sh
    $ ./tools/deployment/developer/nfs/140-openvswitch.sh
    $ ./tools/deployment/developer/nfs/150-libvirt.sh
    $ ./tools/deployment/developer/nfs/160-compute-kit.sh
    $ ./tools/deployment/developer/nfs/170-setup-gateway.sh
    $ ./tools/deployment/developer/common/900-use-it.sh

After successful deployment, `export OS_CLOUD=openstack_helm` on the
OpenStack Helm host so that the OpenStack client can be run.
