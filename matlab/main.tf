terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~>0.7.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~>3.0.2"
    }
  }
}

data "coder_parameter" "cpu" {
  name        = "CPU"
  description = "Choose number of CPU cores (min: 8, max: 20)"
  type        = "number"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/cpu-1.svg"
  mutable     = true
  default     = "8"
  validation {
    min = 4
    max = 20
  }
}

data "coder_parameter" "ram" {
  name        = "RAM"
  description = "Choose amount of RAM (min: 32 GB, max: 64 GB)"
  type        = "number"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  mutable     = true
  default     = "32"
  validation {
    min = 32
    max = 64
  }
}

data "coder_parameter" "gpu" {
  name        = "GPU"
  description = "Do you need GPU?"
  type        = "bool"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/gpu-1.svg"
  mutable     = false
  default     = "true"
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

resource "coder_app" "filebrowser" {
  agent_id     = coder_agent.main.id
  display_name = "File Browser"
  slug         = "filebrowser"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/database.svg"
  url          = "http://localhost:8080"
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
    # make user share directory
    mkdir -p ~/share
    # make user data directory
    mkdir -p ~/data
    # Add matlab to PATH
    export PATH=/opt/matlab/`ls /opt/matlab | grep R*`/bin:$PATH
    # start Matlab browser
    /bin/run.sh -browser 2>&1 | tee ~/matlab_browser.log &
    # start desktop
    /bin/run.sh -vnc 2>&1 | tee ~/matlab.log &
    # Intall and start filebrowser
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
    filebrowser --noauth -r ~/data 2>&1 | tee ~/filebrowser.log &
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

#home_volume
resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-home"
}

resource "docker_container" "workspace" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.matlab.image_id
  cpu_shares = data.coder_parameter.cpu.value
  memory     = data.coder_parameter.ram.value * 1024
  gpus       = "${data.coder_parameter.gpu.value}" == "true" ? "all" : null

  devices {
    host_path = "/dev/nvidia0"
  }

  devices {
    host_path = "/dev/nvidiactl"
  }

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

  ipc_mode = "host"

  # users home directory
  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home_volume.name
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
