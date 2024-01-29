terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    incus = {
      source = "lxc/incus"
    }
  }
}

data "coder_provisioner" "me" {}

provider "incus" {}

data "coder_workspace" "me" {}


data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPUs to allocate to the workspace (1-8)"
  type         = "number"
  default      = "1"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/cpu-3.svg"
  mutable      = true
  validation {
    min = 1
    max = 8
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory to allocate to the workspace in GB (up to 16GB)"
  type         = "number"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  validation {
    min = 1
    max = 16
  }
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"
  dir  = "/home/${local.workspace_user}"

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path /home/${lower(data.coder_workspace.me.owner)}"
    interval     = 60
    timeout      = 1
  }
}

module "code-server" {
  source   = "registry.coder.com/modules/code-server/coder"
  version  = "1.0.2"
  agent_id = coder_agent.main.id
  folder   = "/home/${lower(data.coder_workspace.me.owner)}"
}


resource "incus_volume" "home" {
  name = "coder-${data.coder_workspace.me.id}-home"
  pool = local.pool
}

resource "incus_volume" "docker" {
  name = "coder-${data.coder_workspace.me.id}-docker"
  pool = local.pool
}

resource "incus_cached_image" "ubuntu" {
  source_remote = "ubuntu"
  source_image  = "jammy/amd64"
}

resource "incus_instance" "dev" {
  count = data.coder_workspace.me.start_count
  name  = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
  image = incus_cached_image.ubuntu.fingerprint

  config = {
    "security.nesting"                     = true
    "security.syscalls.intercept.mknod"    = true
    "security.syscalls.intercept.setxattr" = true
    "boot.autostart"                       = true
    "cloud-init.user-data"                 = <<EOF
#cloud-config
hostname: ${lower(data.coder_workspace.me.name)}
users:
  - name: ${local.workspace_user}
    uid: 1000
    gid: 1000
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
runcmd:
  - |
    #!/bin/bash
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh 2>&1 >/dev/null
    usermod -aG docker ${local.workspace_user}
    newgrp docker
  - chown -R ${local.workspace_user}:${local.workspace_user} /home/${local.workspace_user}
  - ["su", "-", "${local.workspace_user}", "-c", "export CODER_AGENT_TOKEN=${coder_agent.main.token} && echo ${base64encode(coder_agent.main.init_script)} | base64 -d | sh"]
EOF
  }

  limits = {
    cpu    = data.coder_parameter.cpu.value
    memory = "${data.coder_parameter.cpu.value}GiB"
  }

  device {
    name = "home"
    type = "disk"
    properties = {
      path   = "/home/${local.workspace_user}"
      pool   = local.pool
      source = incus_volume.home.name
    }
  }

  device {
    name = "docker"
    type = "disk"
    properties = {
      path   = "/var/lib/docker"
      pool   = local.pool
      source = incus_volume.docker.name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = local.pool
    }
  }
}

locals {
  workspace_user = lower(data.coder_workspace.me.owner)
  pool           = "coder"
}
