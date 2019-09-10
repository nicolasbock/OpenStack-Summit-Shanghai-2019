# Deploy Helm

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
