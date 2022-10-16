terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.22.0"
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

locals {
  jupyter-type-arg = "${var.jupyter == "notebook" ? "Notebook" : "Server"}"
  tensorflow-version = "${var.tensorflow_version == "latest" ? "" : "${var.tensorflow_version}"}"
  docker-file-name = "${var.conda_selection == "Yes" ? "Dockerfile.conda" : "Dockerfile"}"
  jupyter-path = "${var.conda_selection == "Yes" ? "/home/${data.coder_workspace.me.owner}/.conda/envs/DL/bin/" : "/home/${data.coder_workspace.me.owner}/.local/bin/"}"
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

variable "tensorflow_version" {
  description = "Tensorflow Version"
  default     = "latest"
  validation {
    condition = contains([
      "latest",
      "2.10.0",
      "2.9.2",
      "2.8.3"
    ], var.tensorflow_version)
    error_message = "Not supported tensorflow version!"   
}
}

variable "conda_selection" {
  description = "Do you need conda environment? (everything will work without it too)"
  default     = "No"
  validation {
    condition = contains([
      "No",
      "Yes"
    ], var.conda_selection)
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

variable "ram" {
  description = "How much RAM for your workspace? (min: 24 GB, max: 128 GB)"
  default     = "24"
  validation { # this will show a text input select
    condition     = contains(["24", "48", "64", "96", "128"], var.ram) # this will show a picker
    error_message = "Ram size must be an integer between 24 and 128 (GB)."
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
  name          = "jupyter-${var.jupyter}"
  icon          = "https://cdn.icon-icons.com/icons2/2667/PNG/512/jupyter_app_icon_161280.png"
  url           = "http://localhost:8888/@${data.coder_workspace.me.owner}/${lower(data.coder_workspace.me.name)}/apps/jupyter-${var.jupyter}/"
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
${local.jupyter-path}/jupyter ${var.jupyter} --no-browser --${local.jupyter-type-arg}App.token='' --ip='*' --${local.jupyter-type-arg}App.base_url=/@${data.coder_workspace.me.owner}/${lower(data.coder_workspace.me.name)}/apps/jupyter-${var.jupyter}/ 2>&1 | tee -a ~/build.log &
EOT
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-home"
}

resource "docker_image" "deeplearning" {
  name = "${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  build {
    path       = "./images/"
    dockerfile = "${local.docker-file-name}"
    tag        = ["matifali/deeplearning:latest"]
    build_arg = {
      USERNAME = "${data.coder_workspace.me.owner}"
      PYTHON_VER = "${var.python_version}"
      TF_VERSION = "${local.tensorflow-version}"
    }
  }
  # Keep alive for other workspaces to use upon deletion
  keep_locally = false
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.deeplearning.image_id
  memory = "${var.ram*1024}"
  gpus = "all"
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
  # users data directory
  volumes {
    container_path = "/home/${data.coder_workspace.me.owner}/data/" 
    host_path      = "/data/${data.coder_workspace.me.owner}/"
    read_only      = false
  }
  # users home directory
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
