#!/bin/bash

set -x -e

: ${OSH_HOSTNAME:=nbock-osh}
: ${IMAGE:=xenial-server-cloudimg-amd64-disk1.img}
#: ${IMAGE:=cirros-0.4.0-x86_64-disk.img}
: ${POOL:=cloud-pool}
: ${DISKSIZE:=80}
: ${MEMORY:=$((20 * 1024))}

resize_partition() {
  sudo modprobe --verbose nbd
  for (( i = 0; i < 5; i++ )); do
    if sudo qemu-nbd --connect=/dev/nbd0 "${image_path}"; then
      break
    fi
    sleep 1
  done
  sudo parted --align=opt --script \
    /dev/nbd0 \
    unit GB \
    print \
    resizepart 1 100% \
    print
  sudo qemu-nbd --disconnect /dev/nbd0
}

copy_ssh_keys() {
  local mountpoint
  mountpoint=$(mktemp -d)
  for (( i = 0; i < 5; i++ )); do
    if sudo qemu-nbd --connect=/dev/nbd0 "${image_path}"; then
      break
    fi
    sleep 1
  done
  sudo mount /dev/nbd0p1 ${mountpoint}
  sudo mkdir -p "${mountpoint}/home/ubuntu/.ssh"
  sudo bash -c "cat '${HOME}/.ssh/id_rsa.pub' >> ${mountpoint}/home/ubuntu/.ssh/authorized_keys"
  sudo chown -R 1000:1000 "${mountpoint}/home/ubuntu"
  sudo umount ${mountpoint}
  sudo qemu-nbd --disconnect /dev/nbd0
}

create_disk() {
  local base_image_path
  local base_image_dirname

  if sudo virsh vol-info "${OSH_HOSTNAME}.qcow2" --pool "${POOL}" > /dev/null 2>&1; then
    echo "Disk ${OSH_HOSTNAME}.qcow2 already exists, deleting it..."
    sudo virsh vol-delete "${OSH_HOSTNAME}.qcow2" --pool "${POOL}"
  fi

  base_image_path=$(sudo virsh vol-path "${IMAGE}" --pool "${POOL}")
  base_image_dirname=$(dirname ${base_image_path})
  image_path="${base_image_dirname}/${OSH_HOSTNAME}.qcow2"

  sudo qemu-img create -f qcow2 -b "${base_image_path}" "${image_path}" $(( ${DISKSIZE} ))G
  sudo virsh pool-refresh "${POOL}"
  sudo qemu-img info "${image_path}"
}

create_cloudinit() {
  cat <<EOF > meta-data
instance-id: ${OSH_HOSTNAME}
local-hostname: ${OSH_HOSTNAME}
public-keys:
  - $(cat ~/.ssh/id_rsa.pub)
EOF
  touch user-data
  if [[ -e config.iso ]]; then
    sudo chown $(id -u) config.iso
  fi
  mkisofs -o config.iso \
    -rational-rock \
    -J meta-data user-data
}

create_vm() {
  sudo virt-install \
    --name "${OSH_HOSTNAME}" \
    --memory "${MEMORY}" \
    --network default \
    --os-variant ubuntu16.04 \
    --disk "${image_path}" \
    --import \
    --disk path=config.iso,device=cdrom \
    --noautoconsole
  sudo virsh console "${OSH_HOSTNAME}"
}

check_exisiting_vm() {
  if sudo virsh dominfo "${OSH_HOSTNAME}" > /dev/null 2>&1; then
    echo "VM already exists"
    sudo virsh destroy "${OSH_HOSTNAME}" || echo "domain was not running"
    sudo virsh undefine "${OSH_HOSTNAME}"
  fi
}

check_exisiting_vm
create_disk
resize_partition
copy_ssh_keys
create_cloudinit
create_vm
