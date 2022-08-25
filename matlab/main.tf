terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.4.9"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.20.2"
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

variable "cpu" {
  description = "How many CPU cores for this workspace?"
  default     = "04"
  validation {
    condition     =  var.cpu > 0 && var.cpu <= 20
    error_message = "Core count should be bwteen 1-20."
  }
}
variable "ram" {
  description = "How much RAM for your workspace? (min: 8 GB, max: 64 GB)"
  default     = "16"
  validation { # this will show a text input
    condition     =  var.ram >= 8 && var.ram <= 96
    error_message = "Ram size must be an integer between 8 and 64 (GB)."
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
  agent_id = coder_agent.dev.id
  name     = "Matlab"
  icon     = "https://img.icons8.com/nolan/344/matlab.png"
  url      = "http://localhost:8888/@${data.coder_workspace.me.owner}/${data.coder_workspace.me.name}/apps/Matlab"
}


resource "coder_agent" "dev" {
  arch           = var.arch
  os             = "linux"
  startup_script = <<EOT
#!/bin/bash
set -euo pipefail
# make user data directory
mkdir -p ~/data
# start Matlab
MWI_BASE_URL="/@${data.coder_workspace.me.owner}/${data.coder_workspace.me.name}/apps/Matlab" matlab-proxy-app &
  EOT
}

variable "docker_image" {
  description = "What Docker image would you like to use for your workspace?"
  default     = "r2022a"

  # List of images available for the user to choose from.
  # Delete this condition to give users free text input.
  validation {
    condition     = contains(["r2022a"], var.docker_image)
    error_message = "Invalid Docker image!"
  }

  # Prevents admin errors when the image is not found
  validation {
    condition     = fileexists("images/${var.docker_image}.Dockerfile")
    error_message = "Invalid Docker image. The file does not exist in the images directory."
  }
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-root"
}

resource "docker_image" "coder_image" {
  name = "coder-base-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  build {
    path       = "./images/"
    dockerfile = "${var.docker_image}.Dockerfile"
    tag        = ["coder-${var.docker_image}:v0.1"]
  }

  # Keep alive for other workspaces to use upon deletion
  keep_locally = true
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.coder_image.latest
  cpu_shares = var.cpu
  memory = "${var.ram*1024}"
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1 
  entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]
  
  # MATLAB Specfic argumnets
  stdin_open = true
  tty = true
  env = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}"]
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/matlab/data"
    #volume_name    = docker_volume.home_volume.name
    host_path      = "/data/${data.coder_workspace.me.owner}/"
    read_only      = false
  }
}
