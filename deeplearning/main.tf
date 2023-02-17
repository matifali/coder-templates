terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.12"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.1"
    }
  }
}

# Admin parameters

variable "arch" {
  default     = "amd64"
  description = "arch: What architecture is your Docker host on?"
  sensitive = true
}

variable "OS" {
  default     = "Linux"
  description = <<-EOF
  What operating system is your Coder host on?
  EOF
  sensitive = true
}

locals {
  tags = {
    "conda (install whatever you need)" = "conda-base",
    "Tensorflow"        = "tensorflow",
    "PyTorch"           = "pytorch",
    "PyTorch Nightly"   = "pytorch-nightly",
    "Tensorflow + PyTorch" = "no-conda",
    "Tensorflow + PyTorch + conda" = "conda",
  }
}

variable "environmnet_type" {
  description = "Which environment type do you want to create?"
  default     = "Tensorflow + PyTorch"
  validation {
    condition = contains([
      "Only conda (install whatever you need)",
      "Tensorflow",
      "PyTorch",
      "PyTorch Nightly",
      "Tensorflow + PyTorch",
      "Tensorflow + PyTorch + conda",
    ], var.environmnet_type)
    error_message = "Invalid environment type!"
  }
}


variable "jupyter" {
  description = "Jupyter IDE type"
  default     = "no"
  validation {
    condition = contains([
      "no",
      "notebook",
      "lab",
    ], var.jupyter)
    error_message = "Invalid selection!"
  }
}

variable "vscode-web" {
  description = "Do you want VS Code Web"
  default     = "no"
  validation {
    condition = contains([
      "no",
      "yes",
    ], var.vscode-web)
    error_message = "Invalid selection!"
  }
  
}

variable "cpu" {
  description = "How many CPU cores for this workspace?"
  default     = "04"
  validation {
    condition     = contains(["04", "08", "16"], var.cpu) # this will show a picker
    error_message = "Invalid CPU count!"
  }
}

variable "ram" {
  description = "Choose RAM for your workspace? (min: 24 GB, max: 128 GB)"
  default     = "16"
  validation {
    condition     = contains(["16", "32","64"], var.ram) # this will show a picker
    error_message = "Invalid RAM size!"
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "coder" {
}

data "coder_workspace" "me" {
}

locals {
  jupyter-type-arg = var.jupyter == "notebook" ? "Notebook" : "Server"
  jupyter-path     = var.environmnet_type == "Full with conda" ? "/home/coder/.conda/envs/DL/bin/" : "/home/coder/.local/bin/"
  docker-tag = local.tags[var.environmnet_type]
}

# jupyter
resource "coder_app" "jupyter" {
  count        = local.docker-tag == "conda-base" ? 0 : var.jupyter == "no" ? 0 : 1 
  agent_id     = coder_agent.main.id
  display_name = "Jupyter"
  slug         = "jupyter-${var.jupyter}"
  icon         = "/icon/jupyter.svg"
  url          = "http://localhost:8888/"
  subdomain    = true
  share        = "owner"
}

resource "coder_app" "code-server" {
  count        = var.vscode-web == "no" ? 0 : 1
  agent_id = coder_agent.main.id
  display_name = "VS Code Web"
  slug         = "code-server"
  url          = "http://localhost:8000?folder=/home/coder/data/"
  icon         = "/icon/code.svg"
  subdomain    = true
  share        = "owner"
}

resource "coder_agent" "main" {
  arch           = var.arch
  os             = "linux"
  startup_script = <<EOT
    #!/bin/bash
    set -euo pipefail
    # Create user data directory
    mkdir -p ~/data
    # make user share directory
    mkdir -p ~/share
    # if docker-tag is not conda-base and jupyter is not no, then start jupyter
    if [ "${local.docker-tag}" != "conda-base" ] && [ "${var.jupyter}" != "no" ]; then
      ${local.jupyter-path}/jupyter ${var.jupyter} --no-browser --${local.jupyter-type-arg}App.token='' --ip='*' 2>&1 | tee -a ~/build.log &
    fi
    # start code-server if vscode-web is yes
    if [ "${var.vscode-web}" == "yes" ]; then
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
  name = "matifali/dockerdl:${local.docker-tag}"
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

#var_volume
resource "docker_volume" "var_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-var"
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
  cpu_shares = var.cpu
  memory     = var.ram * 1024
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
    container_path = "/var/"
    volume_name    = docker_volume.var_volume.name
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
