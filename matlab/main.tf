terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~>3.0.2"
    }
  }
}

data "coder_parameter" "server" {
  name         = "server"
  display_name = "Server"
  icon         = "/icon/container.svg"
  description  = "Choose server"
  default      = "ssh://ctar@ctar301"
  type         = "string"
  mutable      = false
  order        = 1
  option {
    name        = "ctar401"
    description = "CTAR 401"
    value       = "ssh://ctar@ctar401"
    icon        = "/icon/container.svg"
  }
  option {
    name        = "ctar402"
    description = "CTAR 402"
    value       = "ssh://ctar@ctar402"
    icon        = "/icon/container.svg"
  } 
  option {
    name        = "ctar403"
    description = "CTAR 403"
    value       = "ssh://ctar@ctar403"
    icon        = "/icon/container.svg"
  }
  option {
    name        = "ctar404"
    description = "CTAR 404"
    value       = "ssh://ctar@ctar404"
    icon        = "/icon/container.svg"
  }
  option {
    name        = "ctar405"
    description = "CTAR 405"
    value       = "ssh://ctar@ctar405"
    icon        = "/icon/container.svg"
  }
  option {
    name        = "ctar301"
    description = "CTAR 301"
    value       = "ssh://ctar@ctar301"
    icon        = "/icon/container.svg"
  }
  option {
    name        = "ctar302"
    description = "CTAR 302"
    value       = "ssh://ctar@ctar302"
    icon        = "/icon/container.svg"
  }
  option {
    name        = "ctar303"
    description = "CTAR 303"
    value       = "ssh://ctar@ctar303"
    icon        = "/icon/container.svg"
  }
}


provider "docker" {
  host = data.coder_parameter.server.value
  ssh_opts = [
    "-i", "/home/coder/.ssh/id_bilkent_ctar_servers",
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null"
  ]
}

provider "coder" {}

data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

module "filebrowser" {
  source   = "registry.coder.com/modules/filebrowser/coder"
  version  = "1.0.8"
  agent_id = coder_agent.main.id
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
  arch                   = "amd64"
  os                     = "linux"
  startup_script         = <<EOT
    #!/bin/bash
    set -euo pipefail
    # start Matlab browser
    /bin/run.sh -browser >/dev/null 2>&1 &
    echo "Starting Matlab Browser"
    # start desktop
    /bin/run.sh -vnc >/dev/null 2>&1 &
    echo "Starting Matlab Desktop"
  EOT

  display_apps {
    vscode                 = false
    ssh_helper             = false
    port_forwarding_helper = false
  }

  metadata {
    display_name = "CPU Usage"
    interval     = 10
    order        = 1
    key          = "cpu_usage"
    script       = "coder stat cpu"
  }

  metadata {
    display_name = "RAM Usage"
    interval     = 10
    order        = 2
    key          = "ram_usage"
    script       = "coder stat mem"
  }

  metadata {
    display_name = "Disk Usage"
    interval     = 600
    order        = 3
    key          = "disk_usage"
    script       = "coder stat disk $HOME"
  }

  metadata {
    display_name = "Word of the Day"
    interval     = 86400
    order        = 4
    key          = "word_of_the_day"
    script       = <<EOT
      curl -o - --silent https://www.merriam-webster.com/word-of-the-day 2>&1 | awk ' $0 ~ "Word of the Day: [A-z]+" { print $5; exit }'
    EOT
  }
}

resource "docker_image" "matlab" {
  name          = "matifali/matlab:r2023a"
  keep_locally  = true
}

#home_volume
resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}-home"
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.matlab.image_id
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname   = lower(data.coder_workspace.me.name)
  dns        = ["1.1.1.1"]
  entrypoint = ["sh", "-c", coder_agent.main.init_script]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  restart    = "unless-stopped"

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
  item {
    key   = "Server Name"
    value = data.coder_parameter.server.option[index(data.coder_parameter.server.option.*.value, data.coder_parameter.server.value)].description
  }
}