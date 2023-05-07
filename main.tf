terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }
  }
}

resource "proxmox_vm_qemu" "kubernetes_control_plane" {
  for_each = var.control_plane_nodes

  depends_on = [null_resource.cloud_init_snippets_control_plane]

  name        = "${each.key}.${var.domain}"
  target_node = "pve"

  qemu_os = "l26"
  cores   = each.value.cores
  sockets = 1
  memory  = each.value.memory
  scsihw  = "virtio-scsi-pci"

  clone   = var.clone_template
  os_type = "cloud-init"
  agent   = 1

  ssh_user        = var.user
  ssh_private_key = var.ssh_keys.private

  cicustom                = "user=${var.snippet_storage_pool}:snippets/user_data_vm-${each.key}"
  cloudinit_cdrom_storage = var.snippet_storage_pool

  ipconfig0 = "ip=dhcp,ip6=auto"

  vga {
    type = "serial0"
  }

  disk {
    storage = each.value.storage_pool
    type    = "scsi"
    size    = each.value.disk
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
}

resource "proxmox_vm_qemu" "kubernetes_worker" {
  for_each = var.worker_nodes

  # need cloud-init files in snippets, and it appears to get vm ids tripped up
  # if both are running.
  depends_on = [null_resource.cloud_init_snippets_worker, proxmox_vm_qemu.kubernetes_control_plane]

  name        = "${each.key}.${var.domain}"
  target_node = "pve"

  qemu_os = "l26"
  cores   = each.value.cores
  sockets = 1
  memory  = each.value.memory
  scsihw  = "virtio-scsi-pci"

  clone   = var.clone_template
  os_type = "cloud-init"
  agent   = 1

  ssh_user        = var.user
  ssh_private_key = var.ssh_keys.private

  cicustom                = "user=${var.snippet_storage_pool}:snippets/user_data_vm-${each.key}"
  cloudinit_cdrom_storage = var.snippet_storage_pool

  ipconfig0 = "ip=dhcp,ip6=auto"

  vga {
    type = "serial0"
  }

  disk {
    storage = each.value.storage_pool
    type    = "scsi"
    size    = each.value.disk
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
}

output "control_plane_ips" {
  value = {
    for k, vm in proxmox_vm_qemu.kubernetes_control_plane : k => vm.default_ipv4_address
  }
}

output "worker_ips" {
  value = {
    for k, vm in proxmox_vm_qemu.kubernetes_worker : k => vm.default_ipv4_address
  }
}
