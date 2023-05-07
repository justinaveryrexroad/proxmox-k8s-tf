variable "user" {
  type        = string
  description = "default username"
}

variable "ssh_keys" {
  type = object({
    public  = string
    private = string
  })

  sensitive = true
}

variable "domain" {
  type        = string
  description = "Domain Name to use as base of fqdn"
}

variable "clone_template" {
  type        = string
  description = "Base Template to clone from"
}

variable "control_plane_nodes" {
  type = map(object({
    cores        = number
    memory       = number
    disk         = string
    storage_pool = string
    keepalived = object({
      state     = string
      priority  = number
      pass      = string
      router_id = string
    })
  }))
}

variable "worker_nodes" {
  type = map(object({
    cores        = number
    memory       = number
    disk         = string
    storage_pool = string
  }))
}

variable "snippet_dir" {
  type = string
}

variable "pve_host" {
  type = string
}

variable "pve_user" {
  type = string
}

variable "pve_password" {
  type      = string
  sensitive = true
}

variable "snippet_storage_pool" {
  type = string
}

variable "control_plane_keepalived_ip" {
  type = string
}
