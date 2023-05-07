data "cloudinit_config" "k8s_cloud_init_control_plane" {
  for_each      = var.control_plane_nodes
  gzip          = false
  base64_encode = false

  part {
    filename     = "provision.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/files/provision.sh")
  }

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/files/user-data.tftpl", {
      username       = var.user
      ssh_public_key = var.ssh_keys.public
      hostname       = each.key
      fqdn           = "${each.key}.${var.domain}"
      state          = each.value.keepalived.state,
      priority       = each.value.keepalived.priority
      pass           = each.value.keepalived.pass
      router_id      = each.value.keepalived.router_id
      ip             = var.control_plane_keepalived_ip
    })
  }
}

data "cloudinit_config" "k8s_cloud_init_worker" {
  for_each      = var.worker_nodes
  gzip          = false
  base64_encode = false

  part {
    filename     = "provision.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/files/provision.sh")
  }

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/files/user-data-worker.tftpl", {
      username       = var.user
      ssh_public_key = var.ssh_keys.public
      hostname       = each.key
      fqdn           = "${each.key}.${var.domain}"
    })
  }
}

resource "null_resource" "cloud_init_snippets_control_plane" {
  for_each = var.control_plane_nodes

  connection {
    type     = "ssh"
    user     = var.pve_user
    password = var.pve_password
    host     = var.pve_host
  }

  provisioner "file" {
    content     = data.cloudinit_config.k8s_cloud_init_control_plane[each.key].rendered
    destination = "${var.snippet_dir}/user_data_vm-${each.key}"
  }
}

resource "null_resource" "cloud_init_snippets_worker" {
  for_each = var.worker_nodes

  connection {
    type     = "ssh"
    user     = var.pve_user
    password = var.pve_password
    host     = var.pve_host
  }

  provisioner "file" {
    content     = data.cloudinit_config.k8s_cloud_init_worker[each.key].rendered
    destination = "${var.snippet_dir}/user_data_vm-${each.key}"
  }
}
