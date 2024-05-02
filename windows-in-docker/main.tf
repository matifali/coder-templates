terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {}

provider "coder" {}

data "coder_workspace" "me" {}

resource "coder_agent" "dev" {
  arch               = "amd64"
  os                 = "windows"
  connection_timeout = 600
}

resource "local_file" "coder_agent_token" {
  content  = coder_agent.dev.token
  filename = "${path.module}/files/token"
}

data "docker_registry_image" "dockurr" {
  name = "dockurr/windows"
}

resource "docker_image" "dockurr" {
  name = "${data.docker_registry_image.dockurr.name}@${data.docker_registry_image.dockurr.sha256_digest}"
  pull_triggers = [
    data.docker_registry_image.dockurr.sha256_digest,
  ]
  keep_locally = true
}

resource "docker_container" "dockurr" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.dockurr.name
  name       = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
  hostname   = data.coder_workspace.me.name
  env = [
    "RAM_SIZE=16G",
    "CPU_CORES=4",
  ]
  destroy_grace_seconds = 120
  stop_timeout          = 120
  stop_signal           = "SIGINT"
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/storage"
    host_path      = "/home/ubuntu/dockurr"
    read_only      = false
  }
  volumes {
    container_path = "/storage/oem"
    host_path      = "${abspath(path.module)}/files"
    read_only      = true
  }

  devices {
    host_path  = "/dev/kvm"
  }
  capabilities {
    add = ["NET_ADMIN"]
  }
}
