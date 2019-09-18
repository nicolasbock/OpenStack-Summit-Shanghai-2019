#!/bin/bash

set -x -e

: ${OSH_HOSTNAME:=nbock-osh}
: ${IMAGE:=xenial-server-cloudimg-amd64-disk1.img}
: ${IMAGE_POOL:=cloud-pool}
: ${POOL:=default}
: ${DISKSIZE:=80}
: ${MEMORY:=$((32 * 1024))}
: ${VCPUS:=4}
: ${IOTHREADS:=8}

resize_partition() {
  sudo modprobe --verbose nbd
  local success=0
  for (( i = 0; i < 5; i++ )); do
    if sudo qemu-nbd --connect=/dev/nbd0 "${image_path}"; then
      success=1
      break
    fi
    sleep 1
  done
  if (( ${success} != 1 )); then
    echo "could not connect to image"
    exit 1
  fi
  sudo parted --align=opt --script \
    /dev/nbd0 \
    unit GB \
    print \
    resizepart 1 100% \
    print
  if ! sudo qemu-nbd --disconnect /dev/nbd0; then
    echo "could not disconnect nbd0"
    exit 1
  fi
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
  for (( i = 0; i < 5; i++ )); do
    if sudo modprobe --remove --verbose nbd; then
      break
    else
      sleep 1
    fi
  done
}

delete_disk() {
  if sudo virsh vol-info "${OSH_HOSTNAME}.qcow2" --pool "${POOL}" > /dev/null 2>&1; then
    echo "Disk ${OSH_HOSTNAME}.qcow2 already exists, deleting it..."
    sudo virsh vol-delete "${OSH_HOSTNAME}.qcow2" --pool "${POOL}"
  fi
}

create_disk() {
  local base_image_path
  local base_image_dirname
  local tempdir
  local image_size

  delete_disk

  base_image_path=$(sudo virsh vol-path "${IMAGE}" --pool "${IMAGE_POOL}")
  base_image_dirname=$(dirname ${base_image_path})

  tempdir=$(mktemp --directory)
  image_path="${tempdir}/${OSH_HOSTNAME}.qcow2"

  sudo qemu-img create -f qcow2 -b "${base_image_path}" "${image_path}" $(( ${DISKSIZE} ))G
  sudo qemu-img info "${image_path}"

  image_size=$(du --bytes ${image_path} | awk '{print $1}')
  sudo virsh vol-create-as "${POOL}" "${OSH_HOSTNAME}.qcow2" "${image_size}" --format raw
  sudo virsh vol-upload "${OSH_HOSTNAME}.qcow2" "${image_path}" --pool "${POOL}"

  rm -rf "${tempdir}"
  image_path=$(sudo virsh vol-path "${OSH_HOSTNAME}.qcow2" --pool "${POOL}")
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
    -V cidata \
    -J meta-data user-data
}

create_vm() {
  sudo virt-install \
    --name "${OSH_HOSTNAME}" \
    --memory "$(( ${MEMORY} ))" \
    --vcpus "$(( ${VCPUS} ))" \
    --cpu host-passthrough,cache.mode=passthrough \
    --iothreads "$(( ${IOTHREADS} ))" \
    --network default \
    --os-variant ubuntu16.04 \
    --disk vol="${POOL}/${OSH_HOSTNAME}.qcow2" \
    --import \
    --disk path=config.iso,device=cdrom \
    --noautoconsole
  sudo virsh console "${OSH_HOSTNAME}"
}

delete_exisiting_vm() {
  if sudo virsh dominfo "${OSH_HOSTNAME}" > /dev/null 2>&1; then
    echo "VM already exists"
    sudo virsh destroy "${OSH_HOSTNAME}" || echo "domain was not running"
    sudo virsh undefine "${OSH_HOSTNAME}" || echo "domain was not defined"
  fi
  delete_disk
}

remove_ssh_host_key() {
  local vm_fip
  vm_fip=$(sudo virsh domifaddr nbock-osh | grep vnet0 | awk '{print $4}' | cut -d '/' -f 1)
  ssh-keygen -R ${vm_fip}
}

delete_exisiting_vm
create_disk
resize_partition
#copy_ssh_keys
create_cloudinit
create_vm
remove_ssh_host_key
