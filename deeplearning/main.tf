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


module "jetbrains_gateway" {
  source         = "registry.coder.com/modules/jetbrains-gateway/coder"
  version        = "1.0.13"
  agent_id       = coder_agent.main.id
  agent_name     = "main"
  folder         = "/home/coder/data"
  jetbrains_ides = ["PY"]
  default        = "PY"
}

module "filebrowser" {
  source   = "registry.coder.com/modules/filebrowser/coder"
  version  = "1.0.8"
  agent_id = coder_agent.main.id
  folder   = "/home/coder/data"
}

locals {
  jupyter-path     = data.coder_parameter.framework.value == "conda" ? "/home/coder/.conda/envs/DL/bin/jupyter" : "/home/coder/.local/bin/jupyter"
  jupyter-count    = (data.coder_parameter.framework.value == "conda" || data.coder_parameter.jupyter.value == "false") ? 0 : 1
  vscode-web-count = data.coder_parameter.vscode-web.value == "false" ? 0 : 1
}

data "coder_parameter" "ram" {
  name         = "ram"
  display_name = "RAM (GB)"
  description  = "Choose amount of RAM (min: 16 GB, max: 128 GB)"
  type         = "number"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  mutable      = true
  default      = "32"
  order        = 2
  validation {
    min = 16
    max = 128
  }
}

data "coder_parameter" "framework" {
  name         = "framework"
  display_name = "Deep Learning Framework"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  description  = "Choose your preffered framework"
  type         = "string"
  mutable      = false
  default      = "torch"
  order        = 1
  option {
    name        = "PyTorch"
    description = "PyTorch"
    value       = "torch"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/pytorch.svg"
  }
  option {
    name        = "Tensorflow"
    description = "Tensorflow"
    value       = "tf"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tensorflow.svg"
  }
  option {
    name        = "Tensorflow + PyTorch"
    description = "Tensorflow + PyTorch"
    value       = "tf-torch"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tf-torch.svg"
  }
  option {
    name        = "Tensorflow + PyTorch + conda"
    description = "Tensorflow + PyTorch + conda"
    value       = "tf-torch-conda"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tf-torch-conda.svg"
  }
  option {
    name        = "Conda"
    description = "Only conda (install whatever you need)"
    value       = "conda"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/conda.svg"
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
    key   = "RAM (GB)"
    value = data.coder_parameter.ram.value
  }
}

data "coder_parameter" "vscode-web" {
  name        = "VS Code Web"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/code.svg"
  description = "Do you want VS Code Web?"
  type        = "bool"
  mutable     = true
  default     = "false"
  order       = 3
}

data "coder_parameter" "jupyter" {
  name        = "Jupyter"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/jupyter.svg"
  description = "Do you want Jupyter Lab?"
  type        = "bool"
  mutable     = true
  default     = "false"
  order       = 4
}

provider "docker" {}

provider "coder" {}

data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

module "vscode-web" {
  count          = local.vscode-web-count
  source         = "registry.coder.com/modules/vscode-web/coder"
  version        = "1.0.14"
  agent_id       = coder_agent.main.id
  extensions     = ["github.copilot", "ms-python.python", "ms-toolsai.jupyter"]
  accept_license = true
}

module "jupyterlab" {
  count    = local.jupyter-count
  source   = "registry.coder.com/modules/jupyterlab/coder"
  version  = "1.0.8"
  agent_id = coder_agent.main.id
}

resource "coder_agent" "main" {
  arch           = "amd64"
  os             = "linux"
  startup_script = <<EOT
    #!/bin/bash
    set -euo pipefail
    # Create user data directory
    mkdir -p ~/data
    # make user share directory
    mkdir -p ~/share
    EOT

  metadata {
    display_name = "CPU Usage"
    interval     = 10
    order        = 1
    key          = "cpu_usage"
    script       = "coder stat cpu --host"
  }

  metadata {
    display_name = "RAM Usage"
    interval     = 10
    order        = 2
    key          = "ram_usage"
    script       = "coder stat mem --host"
  }

  metadata {
    display_name = "GPU Usage"
    interval     = 10
    order        = 3
    key          = "gpu_usage"
    script       = <<EOT
      nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{printf "%s%%", $1}'
    EOT
  }

  metadata {
    display_name = "GPU Memory Usage"
    interval     = 10
    order        = 4
    key          = "gpu_memory_usage"
    script       = <<EOT
      nvidia-smi --query-gpu=utilization.memory --format=csv,noheader,nounits | awk '{printf "%s%%", $1}'
    EOT
  }

  metadata {
    display_name = "Disk Usage"
    interval     = 600
    order        = 5
    key          = "disk_usage"
    script       = "coder stat disk $HOME"
  }

  metadata {
    display_name = "Word of the Day"
    interval     = 86400
    order        = 6
    key          = "word_of_the_day"
    script       = <<EOT
      #!/bin/bash
      curl -o - --silent https://www.merriam-webster.com/word-of-the-day 2>&1 | awk ' $0 ~ "Word of the Day: [A-z]+" { print $5; exit }'
    EOT
  }

}

locals {
  registry_name = "matifali/dockerdl"
}

data "docker_registry_image" "deeplearning" {
  name = "${local.registry_name}:${data.coder_parameter.framework.value}"
}

resource "docker_image" "deeplearning" {
  name          = "${local.registry_name}@${data.docker_registry_image.deeplearning.sha256_digest}"
  pull_triggers = [data.docker_registry_image.deeplearning.sha256_digest]
  keep_locally  = true
}

#Volumes Resources
#home_volume
resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}-home"
}

#usr_volume
resource "docker_volume" "usr_volume" {
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}-usr"
}

#etc_volume
resource "docker_volume" "etc_volume" {
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}-etc"
}

#opt_volume
resource "docker_volume" "opt_volume" {
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}-opt"
}

resource "docker_container" "workspace" {
  count    = data.coder_workspace.me.start_count
  image    = docker_image.deeplearning.image_id
  memory   = data.coder_parameter.ram.value * 1024
  gpus     = "all"
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  command  = ["sh", "-c", replace(coder_agent.main.init_script, "127.0.0.1", "host.docker.internal")]
  env      = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  restart  = "unless-stopped"

  devices {
    host_path = "/dev/nvidia0"
  }
  devices {
    host_path = "/dev/nvidiactl"
  }
  devices {
    host_path = "/dev/nvidia-uvm-tools"
  }
  devices {
    host_path = "/dev/nvidia-uvm"
  }
  devices {
    host_path = "/dev/nvidia-modeset"
  }

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  ipc_mode = "host"

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
    host_path      = "/data/${data.coder_workspace_owner.me.name}/"
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
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
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

resource "coder_metadata" "workspace" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[count.index].id
  daily_cost  = 50
  item {
    key   = "Framework"
    value = data.coder_parameter.framework.option[index(data.coder_parameter.framework.option.*.value, data.coder_parameter.framework.value)].name
  }
}
