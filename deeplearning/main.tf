terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.14"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.1"
    }
  }
}

locals {
  jupyter-path = (data.coder_parameter.framework.value == "conda-base" || data.coder_parameter.framework.value == "conda") ? "home/coder/.conda/envs/DL/bin" : "home/coder/.local/bin"
}

data "coder_parameter" "cpu" {
  name        = "CPU"
  description = "Choose number of CPU cores (min: 4, max: 16)"
  type        = "number"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  mutable     = true
  default     = "8"
  option {
    name        = "4"
    description = "4"
    value       = "4"
  }
  option {
    name        = "8"
    description = "8"
    value       = "8"
  }
  option {
    name        = "16"
    description = "16"
    value       = "16"
  }
}

data "coder_parameter" "ram" {
  name        = "RAM"
  description = "Choose amount of RAM (min: 16 GB, max: 64 GB)"
  type        = "number"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  mutable     = true
  default     = "32"
  option {
    name        = "16 GB"
    description = "16"
    value       = "16"
  }
  option {
    name        = "32 GB"
    description = "32"
    value       = "32"
  }
  option {
    name        = "64 GB"
    description = "64"
    value       = "64"
  }
}


data "coder_parameter" "framework" {
  name        = "Framework"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/memory.png"
  description = "Choose your preffered framework"
  type        = "string"
  mutable     = false
  default     = "no-conda"
  option {
    name        = "PyTorch"
    description = "PyTorch"
    value       = "pytorch"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/pytorch.svg"
  }
  option {
    name        = "PyTorch Nightly"
    description = "PyTorch Nightly"
    value       = "pytorch-nightly"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/pytorch.svg"
  }
  option {
    name        = "Tensorflow"
    description = "Tensorflow"
    value       = "tensorflow"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tensorflow.svg"
  }
  option {
    name        = "Tensorflow + PyTorch"
    description = "Tensorflow + PyTorch"
    value       = "no-conda"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tf-torch.svg"
  }
  option {
    name        = "Tensorflow + PyTorch + conda"
    description = "Tensorflow + PyTorch + conda"
    value       = "conda"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tf-torch-conda.svg"
  }
  option {
    name        = "Conda"
    description = "Only conda (install whatever you need)"
    value       = "conda-base"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/conda.svg"
  }
}

data "coder_parameter" "vscode-web" {
  name        = "VS Code Web"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/code.svg"
  description = "Do you want VS Code Web?"
  type        = "bool"
  mutable     = true
  default     = true
}

data "coder_parameter" "jupyter" {
  name        = "Jupyter"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/jupyter.svg"
  description = "Choose your preffered Jupyter IDE"
  type        = "string"
  mutable     = true
  default     = "no"
  option {
    name        = "Jupyter Notebook"
    description = "Notebook"
    value       = "notebook"
  }
  option {
    name        = "Jupyter Lab"
    description = "Server"
    value       = "lab"
  }
  option {
    name        = "No"
    description = "No I don't want Jupyter"
    value       = "no"
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
  count        = data.coder_parameter.framework.value == "conda-base" ? 0 : data.coder_parameter.jupyter.value == "no" ? 0 : 1
  agent_id     = coder_agent.main.id
  display_name = "Jupyter ${data.coder_parameter.jupyter.value}"
  slug         = "jupyter${lower(data.coder_parameter.jupyter.value)}"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/jupyter.svg"
  url          = "http://localhost:8888/"
  subdomain    = true
  share        = "owner"
}

resource "coder_app" "code-server" {
  count        = data.coder_parameter.vscode-web.value == false ? 0 : 1
  agent_id     = coder_agent.main.id
  display_name = "VS Code Web"
  slug         = "code-server"
  url          = "http://localhost:8000?folder=/home/coder/data/"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/code.svg"
  subdomain    = true
  share        = "owner"
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
    if [ "${data.coder_parameter.framework.value}" != "conda-base" ] && [ "${data.coder_parameter.jupyter.value}" != "no" ]; then
      ${local.jupyter-path}/jupyter ${data.coder_parameter.jupyter.value} --no-browser --${data.coder_parameter.jupyter.description}App.token='' --ip='*' 2>&1 | tee -a ~/build.log &
    fi
    if [ ${data.coder_parameter.vscode-web.value} ]; then
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

data "docker_registry_image" "dockerdl" {
  name = "matifali/dockerdl:${data.coder_parameter.framework.value}"
}

resource "docker_image" "dockerdl" {
  name          = data.docker_registry_image.dockerdl.name
  pull_triggers = [data.docker_registry_image.dockerdl.sha256_digest]
  # Keep alive for other workspaces to use upon deletion
  keep_locally = true
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
  image      = docker_image.dockerdl.image_id
  cpu_shares = data.coder_parameter.cpu.value
  memory     = data.coder_parameter.ram.value * 1024
  gpus       = "all"
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  command = ["sh", "-c", replace(coder_agent.main.init_script, "127.0.0.1", "host.docker.internal")]
  env     = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  ipc_mode = "host" # recommended for GPU workloads

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
    read_only      = false
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
