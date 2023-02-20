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
  sensitive   = true
}

variable "OS" {
  default     = "Linux"
  description = <<-EOF
  What operating system is your Coder host on?
  EOF
  sensitive   = true
}

variable "cpu" {
  description = "How many CPU cores for this workspace?"
  default     = "08"
  validation {
    condition     = contains(["04", "08", "16", "32", "40"], var.cpu)
    error_message = "value must be one of the options"
  }
}

variable "ram" {
  description = "How much RAM for your workspace? (min: 32 GB, max: 64 GB)"
  default     = "32"
  validation {
    condition     = contains(["32", "48", "64"], var.ram)
    error_message = "value must be one of the options"
  }
}

variable "gpu" {
  description = "Do you need GPU?"
  default     = "No"
  validation {
    condition     = contains(["No", "Yes"], var.gpu)
    error_message = "value must be one of the options"
  }

}

resource "coder_metadata" "compute_resources" {
  count       = data.coder_workspace.me.start_count
  resource_id = data.coder_workspace.me.id
  item {
    key   = "cpu"
    value = var.cpu
  }
  item {
    key   = "ram"
    value = var.ram
  }
  item {
    key   = "gpu"
    value = var.gpu
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "coder" {
}

data "coder_workspace" "me" {
}

# Matlab
resource "coder_app" "matlab_browser" {
  agent_id     = coder_agent.main.id
  display_name = "Matlab Browser"
  slug         = "matlab"
  icon         = "/icon/matlab.svg"
  url          = "http://localhost:8888"
  subdomain    = true
  share        = "owner"
}

resource "coder_app" "matlab_desktop" {
  agent_id     = coder_agent.main.id
  display_name = "MATLAB Desktop"
  slug         = "desktop"
  icon         = "/icon/matlab.svg"
  url          = "http://localhost:6080"
  subdomain    = true
  share        = "owner"
}

resource "coder_agent" "main" {
  arch           = var.arch
  os             = "linux"
  startup_script = <<EOT
    #!/bin/bash
    set -euo pipefail
    # make user share directory
    mkdir -p ~/share
    # Add matlab to PATH
    export PATH=/opt/matlab/`ls /opt/matlab | grep R*`/bin:$PATH
    # start Matlab browser
    /bin/run.sh -browser 2>&1 | tee ~/matlab_browser.log &
    # start desktop
    /bin/run.sh -vnc 2>&1 | tee ~/matlab.log &
    EOT

  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.owner}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.owner}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
  }
}

data "docker_registry_image" "matlab" {
  name = "matifali/matlab:latest"
}

resource "docker_image" "matlab" {
  name          = data.docker_registry_image.matlab.name
  pull_triggers = [data.docker_registry_image.matlab.sha256_digest]
  keep_locally  = true
}

#Volumes Resources
#home_volume
resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-home"
}
resource "coder_metadata" "home_volume" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_volume.home_volume.id
  hide        = true
  item {
    key   = "home_volume"
    value = docker_volume.home_volume.mountpoint
  }
}
#usr_volume
resource "docker_volume" "usr_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-usr"
}
resource "coder_metadata" "usr_volume" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_volume.usr_volume.id
  hide        = true
  item {
    key   = "usr_volume"
    value = docker_volume.usr_volume.mountpoint
  }
}
#var_volume
resource "docker_volume" "var_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-var"
}
resource "coder_metadata" "var_volume" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_volume.var_volume.id
  hide        = true
  item {
    key   = "var_volume"
    value = docker_volume.var_volume.mountpoint
  }
}
#etc_volume
resource "docker_volume" "etc_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-etc"
}
resource "coder_metadata" "etc_volume" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_volume.etc_volume.id
  hide        = true
  item {
    key   = "etc_volume"
    value = docker_volume.etc_volume.mountpoint
  }
}
#opt_volume
resource "docker_volume" "opt_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-opt"
}
resource "coder_metadata" "opt_volume" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_volume.opt_volume.id
  hide        = true
  item {
    key   = "etc_volume"
    value = docker_volume.opt_volume.mountpoint
  }
}
#root_volume
resource "docker_volume" "root_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-root"
}
resource "coder_metadata" "root_volume" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_volume.root_volume.id
  hide        = true
  item {
    key   = "root_volume"
    value = docker_volume.root_volume.mountpoint
  }
}

resource "docker_container" "workspace" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.matlab.image_id
  cpu_shares = var.cpu
  memory     = var.ram * 1024
  gpus       = var.gpu == "Yes" ? "all" : null
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1 
  entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "127.0.0.1", "host.docker.internal")]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  shm_size = 512

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
  volumes {
    container_path = "/root/"
    volume_name    = docker_volume.root_volume.name
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
