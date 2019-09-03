=============
 Deploy Helm
=============

Create instance on ECP
======================

- image:
  ubuntu-16.04-server-cloudimg-amd64-disk1.img (e7a40226-3523-4f0f-87d8-d8dc91bbf4a3)
- flavor:
  m2.xlarge
- security_groups:
  ping/ssh
  default

Prepare instance
================

- Create file:
  /etc/sudoers.d/50-root
.. code-block::

   root ALL=(ALL) NOPASSWD:ALL

- Configure git:
.. code-block: bash

   $ git config --global user.name 'Nicolas Bock'
   # git config --global user.email nicolas.bock@suse.com

- Clone repositories:
.. code-block:: bash

   $ git clone https://opendev.org/openstack/openstack-helm-infra.git
   $ git clone https://opendev.org/openstack/openstack-helm.git

- Fix deployment variables:
  openstack-helm-infra/roles/osh-run-script/defaults/main.yaml
.. code-block: yaml

   osh_params:
     openstack_release: newton
     container_distro_name: ubuntu
     container_distro_version: xenial

- Fix hosts with the /etc/hostname:
  /etc/hosts
.. code-block::

   127.0.0.1 nbock-tumbleweed

Local infra modification patch
------------------------------

.. code-block:: diff

From 428dc34e88292b0e844f82eb7a8ed8ce5209c92a Mon Sep 17 00:00:00 2001
From: Nicolas Bock <nicolas.bock@suse.com>
Date: Fri, 30 Aug 2019 16:48:45 +0000
Subject: [PATCH] Local modifications

---
 tools/deployment/common/005-deploy-k8s.sh               | 7 ++++---
 tools/images/kubeadm-aio/assets/opt/playbooks/vars.yaml | 5 +++--
 2 files changed, 7 insertions(+), 5 deletions(-)

diff --git a/tools/deployment/common/005-deploy-k8s.sh b/tools/deployment/common/005-deploy-k8s.sh
index e78d949..0ed4ac5 100755
--- a/tools/deployment/common/005-deploy-k8s.sh
+++ b/tools/deployment/common/005-deploy-k8s.sh
@@ -40,8 +40,9 @@ function configure_resolvconf {
   # the resolv.conf file unless using a proxy, then use the existing DNS servers,
   # as custom DNS nameservers are commonly required when using a proxy server.
   if [ -z "${HTTP_PROXY}" ]; then
-    sudo bash -c "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"
-    sudo bash -c "echo 'nameserver 8.8.4.4' >> /etc/resolv.conf"
+    sudo bash -c "echo 'nameserver 44.71.0.4' >> /etc/resolv.conf"
+    sudo bash -c "echo 'nameserver 44.71.0.3' >> /etc/resolv.conf"
+    sudo bash -c "echo 'nameserver 44.71.0.2' >> /etc/resolv.conf"
   else
     sed -ne "s/nameserver //p" /etc/resolv.conf.backup | while read -r ns; do
       sudo bash -c "echo 'nameserver ${ns}' >> /etc/resolv.conf"
@@ -53,7 +54,7 @@ function configure_resolvconf {
 }
 
 # NOTE: Clean Up hosts file
-sudo sed -i '/^127.0.0.1/c\127.0.0.1 localhost localhost.localdomain localhost4localhost4.localdomain4' /etc/hosts
+sudo sed -i "/^127.0.0.1/c\127.0.0.1 localhost localhost.localdomain localhost4localhost4.localdomain4 $(hostname)" /etc/hosts
 sudo sed -i '/^::1/c\::1 localhost6 localhost6.localdomain6' /etc/hosts
 
 # Install required packages for K8s on host
diff --git a/tools/images/kubeadm-aio/assets/opt/playbooks/vars.yaml b/tools/images/kubeadm-aio/assets/opt/playbooks/vars.yaml
index 17038fa..7e06f47 100644
--- a/tools/images/kubeadm-aio/assets/opt/playbooks/vars.yaml
+++ b/tools/images/kubeadm-aio/assets/opt/playbooks/vars.yaml
@@ -20,8 +20,9 @@ all:
       gid: null
       home: null
     external_dns_nameservers:
-      - 8.8.8.8
-      - 8.8.4.4
+      - 44.71.0.4
+      - 44.71.0.3
+      - 44.71.0.2
     calico:
       prometheus_port: 9091
     cluster:
-- 
2.7.4

Gate commands
=============

.. code-block:: bash

   $ ./tools/deployment/common/install-packages.sh
   $ ./tools/deployment/common/deploy-k8s.sh
   $ ./tools/deployment/common/setup-client.sh
