terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.5"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.23"
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

# variable "cpu" {
#   description = "How many CPU cores for this workspace?"
#   default     = "10"
#   validation {
#     condition     = contains(["05", "10", "20", "30", "40"], var.cpu)
#     error_message = "value must be one of the options"
#   }
# }
variable "ram" {
  description = "How much RAM for your workspace? (min: 32 GB, max: 128 GB)"
  default     = "32"
  validation {
    condition     = contains(["32", "48", "64", "96", "128"], var.ram)
    error_message = "value must be one of the options"
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
  agent_id     = coder_agent.dev.id
  display_name = "Matlab Browser"
  slug         = "matlab"
  icon         = "https://img.icons8.com/nolan/344/matlab.png"
  url          = "http://localhost:8888"
  subdomain    = true
  share        = "owner"
}


resource "coder_app" "matlab_desktop" {
  agent_id     = coder_agent.dev.id
  display_name = "MATLAB Desktop"
  slug         = "desktop"
  icon         = "https://img.icons8.com/nolan/344/matlab.png"
  url          = "http://localhost:6080"
  subdomain    = true
  share        = "owner"
}

resource "coder_agent" "dev" {
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
}

variable "docker_image" {
  description = "What matlab version do you want to use?"
  default     = "r2022b"

  # List of images available for the user to choose from.
  # Delete this condition to give users free text input.
  validation {
    condition     = contains(["r2022b"], var.docker_image)
    error_message = "Invalid Docker image!"
  }

  # Prevents admin errors when the image is not found
  validation {
    condition     = fileexists("images/${var.docker_image}.Dockerfile")
    error_message = "Invalid Docker image. The file does not exist in the images directory."
  }
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

resource "docker_image" "matlab" {
  name = "coder-matlab-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  build {
    path       = "./images/"
    dockerfile = "${var.docker_image}.Dockerfile"
    tag        = ["coder-matlab-${var.docker_image}:latest"]
  }

  # Keep alive for other workspaces to use upon deletion
  keep_locally = true
}

resource "docker_container" "workspace" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.matlab.image_id
  cpu_shares = 20 # 50% of 40 threads
  memory     = var.ram * 1024
  # Use gpu if available
  runtime = "nvidia"
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1 
  entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]


  env = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}"]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  shm_size = 512
  # users home directory
  volumes {
    container_path = "/home/matlab"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  # personal data directory
  volumes {
    container_path = "/home/matlab/data"
    host_path      = "/data/${data.coder_workspace.me.owner}"
    read_only      = false
  }
  # shared data directory
  volumes {
    container_path = "/home/matlab/share"
    host_path      = "/data/share"
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
