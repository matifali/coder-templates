terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.3"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.23.0"
    }
  }
}

# Admin parameters

variable "arch" {
  default = "amd64"
  description = "arch: What architecture is your Docker host on?"
  sensitive = true
}

variable "OS" {
  default = "Linux"
  description = <<-EOF
  What operating system is your Coder host on?
  EOF
  sensitive = true
}

variable "python_version" {
  description = "Python Version"
  default     = "3.10"
  validation {
    condition = contains([
      "3.10",
      "3.9"
    ], var.python_version)
    error_message = "Not supported python version!"   
}
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "coder" {
}

data "coder_workspace" "me" {
}

# jupyter
resource "coder_app" "jupyter" {
  agent_id      = coder_agent.dev.id
  name          = "jupyter-lab"
  slug          = "jupyter-lab"
  icon          = "https://cdn.icon-icons.com/icons2/2667/PNG/512/jupyter_app_icon_161280.png"
  url           = "http://localhost:8888/@${data.coder_workspace.me.owner}/${lower(data.coder_workspace.me.name)}/apps/jupyter-lab/"
  subdomain     = false
  share         = "owner"
}

resource "coder_agent" "dev" {
  arch = var.arch
  os   = "linux"
  startup_script = <<EOT
#!/bin/bash
set -euo pipefail
# Create user data directory
mkdir -p ~/data
# make user share directory
mkdir -p ~/share
# start jupyter
/home/${data.coder_workspace.me.owner}/.local/bin/jupyter lab --no-browser --ServerApp.token='' --ip='*' --ServerApp.base_url=/@${data.coder_workspace.me.owner}/${lower(data.coder_workspace.me.name)}/apps/jupyter-lab/ 2>&1 | tee -a ~/build.log &
EOT
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-home"
}

resource "docker_image" "aihwkit" {
  name = "${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  build {
    path       = "./images/"
    dockerfile = "Dockerfile"
    tag        = ["matifali/aihwkit:latest"]
    build_arg = {
      USERNAME = "${data.coder_workspace.me.owner}"
      PYTHON_VER = "${var.python_version}"
    }
  }
  # Keep alive for other workspaces to use upon deletion
  keep_locally = false
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.aihwkit.image_id
  memory = 65536
  gpus = "all"
  # Uses lower() to avoid Docker restriction on container names.
  name = "${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  command = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]
  env     = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}"]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/${data.coder_workspace.me.owner}/data/" 
    host_path      = "/data/${data.coder_workspace.me.owner}/"
    read_only      = false
  }
  volumes {
    container_path = "/home/${data.coder_workspace.me.owner}"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  # shared data directory
  volumes {
    container_path = "/home/${data.coder_workspace.me.owner}/share"
    host_path      = "/data/share/"
    read_only      = true
  }
}
