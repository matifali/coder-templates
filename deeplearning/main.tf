terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.6"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "2.25.0"
    }
  }
}

# Admin parameters

variable "arch" {
  default     = "amd64"
  description = "arch: What architecture is your Docker host on?"
  sensitive   = true
}

variable "OS" {
  default     = "Linux"
  description = <<-EOF
  What operating system is your Coder host on?
  EOF
  sensitive   = true
}

variable "environmnet_type" {
  description = "Which environment type do you want to create?"
  default     = "Full"
  validation {
    condition = contains([
      "Full",
      "Full + conda",
      "PyTorch",
      "PyTorch Nightly",
      "Tensorflow"
    ], var.environmnet_type)
    error_message = "Not supported!"
  }
}

variable "jupyter" {
  description = "Jupyter IDE type"
  default     = "notebook"
  validation {
    condition = contains([
      "notebook",
      "lab",
    ], var.jupyter)
    error_message = "Invalid Jupyter!"
  }
}

variable "cpu" {
  description = "How many CPU cores for this workspace?"
  default     = "08"
  validation {
    condition     = contains(["08", "16", "32"], var.cpu) # this will show a picker
    error_message = "Invalid CPU count!"
  }
}

variable "ram" {
  description = "Choose RAM for your workspace? (min: 24 GB, max: 128 GB)"
  default     = "24"
  validation {
    condition     = contains(["24", "48", "64"], var.ram) # this will show a picker
    error_message = "Ram size must be an integer between 24 and 64 (GB)."
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
  docker-tag       = var.environmnet_type == "Full" ? "no-conda" : var.environmnet_type == "Full with conda" ? "conda" : var.environmnet_type == "PyTorch" ? "pytorch" : var.environmnet_type == "Tensorflow" ? "tensorflow" : "pytorch-nightly"
}

# jupyter
resource "coder_app" "jupyter" {
  agent_id     = coder_agent.dev.id
  display_name = "Jupyter"
  slug         = "jupyter-${var.jupyter}"
  icon         = "https://cdn.icon-icons.com/icons2/2667/PNG/512/jupyter_app_icon_161280.png"
  url          = "http://localhost:8888/"
  subdomain    = true
  share        = "owner"
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id

  display_name = "VSCode"
  slug         = "code-server"
  url          = "http://localhost:8000?folder=/home/coder/data/"
  icon         = "/icon/code.svg"
  subdomain    = true
  share        = "owner"
}

resource "coder_agent" "dev" {
  arch           = var.arch
  os             = "linux"
  startup_script = <<EOT
#!/bin/bash
set -euo pipefail
# Create user data directory
mkdir -p ~/data
# make user share directory
mkdir -p ~/share
# start jupyter
${local.jupyter-path}/jupyter ${var.jupyter} --no-browser --${local.jupyter-type-arg}App.token='' --ip='*' 2>&1 | tee -a ~/build.log &
# start code-server
code-server --accept-server-license-terms serve-local --without-connection-token --quality stable --telemetry-level off 2>&1 | tee -a ~/code-server.log &
EOT
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
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
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
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
  command = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]
  env     = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}"]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  ipc_mode = "host" # required for PyTorch with multiple workers
  # users data directory
  volumes {
    container_path = "/home/coder/data/"
    host_path      = "/data/${data.coder_workspace.me.owner}/"
    read_only      = false
  }
  # users home directory
  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home_volume.name
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
