terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~>0.11.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~>3.0.2"
    }
  }
}

data "coder_parameter" "ram" {
  name         = "ram"
  display_name = "RAM (GB)"
  description  = "Choose amount of RAM (min: 32 GB, max: 128 GB)"
  type         = "number"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  mutable      = true
  order        = 1
  default      = "32"
  validation {
    min = 32
    max = 128
  }
}

data "coder_parameter" "gpu" {
  name         = "gpu"
  display_name = "GPU"
  description  = "Do you need GPU?"
  type         = "bool"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/gpu-1.svg"
  mutable      = false
  order        = 2
  default      = "true"
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
  startup_script_timeout = 180
  startup_script         = <<EOT
    #!/bin/bash
    set -euo pipefail
    # make user share directory
    mkdir -p ~/share
    # make user data directory
    mkdir -p ~/data
    # start Matlab browser
    /bin/run.sh -browser >/dev/null 2>&1 &
    echo "Starting Matlab Browser"
    # start desktop
    /bin/run.sh -vnc >/dev/null 2>&1 &
    echo "Starting Matlab Desktop"
    # Intall and start filebrowser
    echo "Installing and starting File Browser"
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
    filebrowser --noauth -r ~/data >/dev/null 2>&1 &
  EOT

  metadata {
    display_name = "CPU Usage Workspace"
    interval     = 10
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
  }

  metadata {
    display_name = "RAM Usage Workspace"
    interval     = 10
    key          = "1_ram_usage"
    script       = "coder stat mem"
  }

  metadata {
    display_name = "CPU Usage Host"
    interval     = 10
    key          = "2_cpu_usage"
    script       = "coder stat cpu --host"
  }

  metadata {
    display_name = "RAM Usage Host"
    interval     = 10
    key          = "3_ram_usage"
    script       = "coder stat mem --host"
  }

  metadata {
    display_name = "GPU Usage"
    interval     = 10
    key          = "4_gpu_usage"
    script       = <<EOT
      (nvidia-smi 1> /dev/null 2> /dev/null) && (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{printf "%s%%", $1}') || echo "N/A"
    EOT
  }

  metadata {
    display_name = "GPU Memory Usage"
    interval     = 10
    key          = "5_gpu_memory_usage"
    script       = <<EOT
      (nvidia-smi 1> /dev/null 2> /dev/null) && (nvidia-smi --query-gpu=utilization.memory --format=csv,noheader,nounits | awk '{printf "%s%%", $1}') || echo "N/A"
    EOT
  }

  metadata {
    display_name = "Disk Usage"
    interval     = 600
    key          = "6_disk_usage"
    script       = "coder stat disk $HOME"
  }

  metadata {
    display_name = "Word of the Day"
    interval     = 86400
    key          = "5_word_of_the_day"
    script       = <<EOT
      curl -o - --silent https://www.merriam-webster.com/word-of-the-day 2>&1 | awk ' $0 ~ "Word of the Day: [A-z]+" { print $5; exit }'
    EOT
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
  count  = data.coder_workspace.me.start_count
  image  = docker_image.matlab.image_id
  memory = data.coder_parameter.ram.value * 1024
  gpus   = "${data.coder_parameter.gpu.value}" == "true" ? "all" : null
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname   = lower(data.coder_workspace.me.name)
  dns        = ["1.1.1.1"]
  entrypoint = ["sh", "-c", coder_agent.main.init_script]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

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
    container_path = "/home/matlab"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  # users data directory
  volumes {
    container_path = "/home/matlab/data/"
    host_path      = "/data/${data.coder_workspace.me.owner}/"
    read_only      = false
  }

  # shared data directory
  volumes {
    container_path = "/home/matlab/share"
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

resource "coder_metadata" "workspace" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[count.index].id
  daily_cost  = 50
}
