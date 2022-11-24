terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.3"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.23.0"
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
    condition     = contains(["08", "16", "32"], var.cpu) # this will show a picker
    error_message = "Invalid CPU count!"
  }
}

variable "ram" {
  description = "How much RAM for your workspace? (min: 24 GB, max: 128 GB)"
  default     = "24"
  validation {
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

# no-vnc
resource "coder_app" "novnc" {
  agent_id     = coder_agent.dev.id
  display_name = "noVNC"
  slug         = "novnc"
  icon         = "http://ppswi.us/noVNC/app/images/icons/novnc-icon.svg"
  url          = "http://localhost:6080"
  subdomain    = false
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
# run startup script
bash /startup.sh > /dev/null 2>&1 | tee ~/startup.log
EOT
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
}


# data "docker_registry_image" "ubuntu" {
#   name = "fredblgr/ubuntu-novnc:22.04"
# }

# resource "docker_image" "ubuntu" {
#   name          = data.docker_registry_image.ubuntu.name
#   pull_triggers = [data.docker_registry_image.ubuntu.sha256_digest]
# }

resource "docker_image" "ubuntu" {
  name = "ubuntu-novnc"
  build {
    dockerfile = "./Dockerfile"
    path       = "."
    tag        = ["latest"]
    build_arg = {
      USERNAME = "${data.coder_workspace.me.owner}"
    }


  }
}

resource "docker_container" "workspace" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.ubuntu.image_id
  cpu_shares = var.cpu
  memory     = var.ram * 1024
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  command = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]
  env     = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}", "USERNAME=${data.coder_workspace.me.owner}", "USERID=1000"]

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
    read_only      = false
  }
}
