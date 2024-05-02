terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

provider "docker" {}

provider "coder" {}

data "coder_workspace" "me" {}

resource "coder_agent" "dev" {
  arch               = "amd64"
  os                 = "windows"
  connection_timeout = 1800
}

resource "local_file" "coder_agent_token" {
  content  = coder_agent.dev.token
  filename = "${path.root}/build/files/token"
}

resource "docker_image" "dockurr" {
  name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-dockurr"
  build {
    context = "./build"
  }
  keep_locally = true
  triggers = {
    dockerfile = sha1(join("", [for f in fileset(path.module, "build/Dockerfile") : filesha1(f)]))
    token      = sha1(local_file.coder_agent_token.content)
  }
  depends_on = [local_file.coder_agent_token]
}


resource "docker_volume" "storage" {
  name = "coder-${data.coder_workspace.me.id}-storage"
}

resource "docker_container" "dockurr" {
  count    = data.coder_workspace.me.start_count
  image    = docker_image.dockurr.name
  name     = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
  hostname = data.coder_workspace.me.name
  env = [
    "RAM_SIZE=16G",
    "CPU_CORES=4",
  ]

  # The following ports are added for debugging purposes
  # TODO: Remove these ports when agent startup is figured out
  ports {
    internal = 8006
    external = 8010
  }

  destroy_grace_seconds = 120
  stop_timeout          = 120
  stop_signal           = "SIGINT"

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  volumes {
    container_path = "/storage"
    volume_name    = docker_volume.storage.name
    read_only      = false
  }

  volumes {
    container_path = "/storage/win11x64.iso"
    host_path      = "/home/ubuntu/windows/win11x64.iso"
    read_only      = true
  }

  devices {
    host_path = "/dev/kvm"
  }

  capabilities {
    add = ["NET_ADMIN"]
  }
}
