terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.20"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

locals {
  jupyter-path      = "/usr/local/bin/jupyter"
  jupyter-count     = data.coder_parameter.jupyter.value == "false" ? 0 : 1
  code-server-count = data.coder_parameter.code-server.value == "false" ? 0 : 1
  ngc-version       = "23.02"
}

data "coder_parameter" "cpu" {
  name        = "CPU"
  description = "Choose number of CPU cores (min: 4, max: 16)"
  type        = "number"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  mutable     = true
  default     = "8"
  validation {
    min = 4
    max = 16
  }
}

data "coder_parameter" "ram" {
  name        = "RAM"
  description = "Choose amount of RAM (min: 16 GB, max: 128 GB)"
  type        = "number"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  mutable     = true
  default     = "32"
  validation {
    min = 16
    max = 128
  }
}

data "coder_parameter" "framework" {
  name        = "Framework"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  description = "Choose your preffered framework"
  type        = "string"
  default     = "nvcr.io/nvidia/pytorch:${local.ngc-version}-py3"
  mutable     = false
  option {
    name        = "Nvidia PyTorch"
    description = "Nvidia NGC PyTorch"
    value       = "nvcr.io/nvidia/pytorch:${local.ngc-version}-py3"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/pytorch.svg"
  }
  option {
    name        = "Nvidia Tensorflow"
    description = "Nvidia NGC Tensorflow"
    value       = "nvcr.io/nvidia/tensorflow:${local.ngc-version}-tf2-py3"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tensorflow.svg"
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_image.deeplearning.id
  icon        = data.coder_parameter.framework.option[index(data.coder_parameter.framework.option.*.value, data.coder_parameter.framework.value)].icon
  item {
    key   = "Framework"
    value = data.coder_parameter.framework.option[index(data.coder_parameter.framework.option.*.value, data.coder_parameter.framework.value)].name
  }
  item {
    key   = "CPU Cores"
    value = data.coder_parameter.cpu.value
  }
  item {
    key   = "RAM (GB)"
    value = data.coder_parameter.ram.value
  }
}

data "coder_parameter" "code-server" {
  name        = "VS Code Web"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/code.svg"
  description = "Do you want VS Code Web?"
  type        = "bool"
  mutable     = true
  default     = "false"
}

data "coder_parameter" "jupyter" {
  name        = "Jupyter"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/jupyter.svg"
  description = "Do you want Jupyter Lab?"
  type        = "bool"
  mutable     = true
  default     = "false"

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
  count        = local.jupyter-count
  agent_id     = coder_agent.main.id
  display_name = "Jupyter Lab"
  slug         = "jupyter"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/jupyter.svg"
  url          = "http://localhost:8888/"
  subdomain    = true
  share        = "owner"
}

resource "coder_app" "code-server" {
  count        = local.code-server-count
  agent_id     = coder_agent.main.id
  display_name = "VS Code Web"
  slug         = "code-server"
  url          = "http://localhost:8000?folder=/home/coder/data/"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/code.svg"
  subdomain    = true
  share        = "owner"
}

resource "coder_app" "filebrowser" {
  count        = 1
  agent_id     = coder_agent.main.id
  display_name = "File Browser"
  slug         = "filebrowser"
  url          = "http://localhost:8080/"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/database.svg"
  subdomain    = true
  share        = "owner"
}

resource "coder_agent" "main" {
  arch                   = "amd64"
  os                     = "linux"
  login_before_ready     = false
  startup_script_timeout = 180
  startup_script         = <<EOT
    #!/bin/bash
    set -euo pipefail

    # Create a user with name coder and uid:gid 1000:1000
    useradd -m -u 1000 -U -s /bin/bash coder
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
    # Create user data directory
    mkdir -p /home/coder/data && chown -R coder:coder /home/coder/data
    # make user share directory
    mkdir -p /home/coder/share && chown -R coder:coder /home/coder/share

    # Install and launch filebrowser
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
    filebrowser --noauth --root ~/data 2>&1 | tee -a ~/filebrowser.log &
  
    # launch jupyter
    if [ "${data.coder_parameter.jupyter.value}" == "true" ];
    then
      ${local.jupyter-path}/jupyter lab --no-browser --ServerApp.token='' --ip='*' 2>&1 | tee -a ~/jupyter.log &
    fi

    # Install and launch code-server
    if [ "${data.coder_parameter.code-server.value}" == "true" ];
    then
      wget -O- https://aka.ms/install-vscode-server/setup.sh | sh
      code-server --accept-server-license-terms serve-local --without-connection-token --quality stable --telemetry-level off 2>&1 | tee -a ~/code-server.log &
    fi

    EOT

  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.owner}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.owner}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
  }
}

data "docker_registry_image" "deeplearning" {
  name = data.coder_parameter.framework.value
}

resource "docker_image" "deeplearning" {
  name          = data.docker_registry_image.deeplearning.name
  pull_triggers = [data.docker_registry_image.deeplearning.sha256_digest]
  keep_locally  = true
}

#Volumes Resources
#home_volume
resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-home"
}

#usr_volume
resource "docker_volume" "usr_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-usr"
}

#etc_volume
resource "docker_volume" "etc_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-etc"
}

#opt_volume
resource "docker_volume" "opt_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-opt"
}

resource "docker_container" "workspace" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.deeplearning.image_id
  cpu_shares = data.coder_parameter.cpu.value
  memory     = data.coder_parameter.ram.value * 1024
  gpus       = "all"
  # See https://github.com/NVIDIA/nvidia-docker/issues/1671#issuecomment-1420855027
  devices {
    host_path = "/dev/nvidia0"
  }
  devices {
    host_path = "/dev/nvidiactl"
  }
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  command  = ["sh", "-c", replace(coder_agent.main.init_script, "127.0.0.1", "host.docker.internal")]
  env      = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  ipc_mode = "host"

  # Start as use with UID and GID of 1000
  user = "1000:1000"

  # users home directory
  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  volumes {
    container_path = "/usr/"
    volume_name    = docker_volume.usr_volume.name
    read_only      = false
  }
  volumes {
    container_path = "/etc/"
    volume_name    = docker_volume.etc_volume.name
    read_only      = false
  }
  volumes {
    container_path = "/opt/"
    volume_name    = docker_volume.opt_volume.name
    read_only      = false
  }
  # users data directory
  volumes {
    container_path = "/home/coder/data/"
    host_path      = "/data/${data.coder_workspace.me.owner}/"
    read_only      = false
  }
  # shared data directory
  volumes {
    container_path = "/home/coder/share"
    host_path      = "/data/share/"
    read_only      = true
  }

  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}
