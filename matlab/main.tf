terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.5"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.23.1"
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
resource "coder_app" "matlab" {
  agent_id     = coder_agent.dev.id
  display_name = "Matlab Web"
  slug         = "matlab"
  icon         = "https://img.icons8.com/nolan/344/matlab.png"
  url          = "http://localhost:8888/index.html"
  subdomain    = true
  share        = "owner"
}


resource "coder_app" "desktop" {
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
}

resource "docker_image" "coder_image" {
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
  image      = docker_image.coder_image.image_id
  cpu_shares = 20 # 50% of 40 threads
  memory     = var.ram * 1024
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1 
  entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]


  env        = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}",  "MWI_BASE_URL=/@${data.coder_workspace.me.owner}/${data.coder_workspace.me.name}/apps/matlab"]

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
}
