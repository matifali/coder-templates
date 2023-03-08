terraform {
  required_providers {
    fly = {
      source  = "fly-apps/fly"
      version = "~>0.0.21"
    }
    coder = {
      source  = "coder/coder"
      version = "~>0.6.15"
    }
  }
}

provider "fly" {
  useinternaltunnel    = true
  internaltunnelorg    = data.coder_parameter.fly-org.value
  internaltunnelregion = data.coder_parameter.region.value
}


resource "fly_app" "workspace" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  org  = data.coder_parameter.fly-org.value
}

resource "fly_ip" "workspace-ip4" {
  app  = fly_app.workspace.name
  type = "v4"
}

resource "fly_ip" "workspace-ip6" {
  app  = fly_app.workspace.name
  type = "v6"
}

resource "fly_volume" "hame-volume" {
  app    = fly_app.workspace.name
  name   = "coder_${data.coder_workspace.me.owner}_${lower(data.coder_workspace.me.name)}_home"
  size   = data.coder_parameter.volume-size.value
  region = data.coder_parameter.region.value
}

resource "fly_machine" "workspace" {
  app      = fly_app.workspace.name
  region   = data.coder_parameter.region.value
  name     = data.coder_workspace.me.name
  image    = data.coder_parameter.docker-image.value
  cpus     = data.coder_parameter.cpu.value
  memorymb = data.coder_parameter.memory.value * 1024
  env = {
    CODER_AGENT_TOKEN = "${coder_agent.main.token}"
  }
  entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "${fly_ip.workspace-ip4.address}")] # replace localhost with the IP of the workspace
  services = [
    {
      ports = [
        {
          port     = 443
          handlers = ["tls", "http"]
        },
        {
          port     = 80
          handlers = ["http"]
        }

      ]
      protocol        = "tcp",
      "internal_port" = 80
    },
    {
      ports = [
        {
          port     = 8080
          handlers = ["tls", "http"]
        }
      ]
      protocol        = "tcp",
      "internal_port" = 8080
    }
  ]
  mounts = [
    {
      volume = fly_volume.hame-volume.id
      path   = "/home/coder"
    }
  ]
}

data "coder_parameter" "docker-image" {
  name        = "Docker Image"
  description = "The docker image to use for the workspace"
  default     = "codercom/code-server:latest"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/docker.svg"
}

data "coder_parameter" "cpu" {
  name        = "CPU"
  description = "The number of CPUs to allocate to the workspace (1-8)"
  type        = "number"
  default     = "1"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/cpu-3.svg"
  mutable     = true
  validation {
    min = 1
    max = 8
  }
}

data "coder_parameter" "memory" {
  name        = "Memory (GB)"
  description = "The amount of memory to allocate to the workspace in GB (1-8)"
  type        = "number"
  default     = "1"
  icon        = "/icon/memory.svg"
  mutable     = true
  validation {
    min = 1
    max = 8
  }
}

data "coder_parameter" "volume-size" {
  name        = "Volume Size"
  description = "The size of the volume to create for the workspace in GB (1-20)"
  type        = "number"
  default     = "3"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/database.svg"
  validation {
    min = 1
    max = 20
  }
}

# You can see all available regions here: https://fly.io/docs/reference/regions/
data "coder_parameter" "region" {
  name        = "Region"
  description = "The region to deploy the workspace in"
  default     = "ams"
  icon        = "/emojis/1f30e.png"
  option {
    name  = "Amsterdam, Netherlands"
    value = "ams"
    icon  = "/emojis/1f1f3-1f1f1.png"
  }
  option {
    name  = "Frankfurt, Germany"
    value = "fra"
    icon  = "/emojis/1f1e9-1f1ea.png"
  }
  option {
    name  = "Paris, France"
    value = "cdg"
    icon  = "/emojis/1f1eb-1f1f7.png"
  }
  option {
    name  = "Denver, Colorado (US)"
    value = "den"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "Dallas, Texas (US)"
    value = "dal"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "Hong Kong"
    value = "hkg"
    icon  = "/emojis/1f1ed-1f1f0.png"
  }
  option {
    name  = "Los Angeles, California (US)"
    value = "lax"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "London, United Kingdom"
    value = "lhr"
    icon  = "/emojis/1f1ec-1f1e7.png"
  }
  option {
    name  = "Chennai, India"
    value = "maa"
    icon  = "/emojis/1f1ee-1f1f3.png"
  }
  option {
    name  = "Tokyo, Japan"
    value = "nrt"
    icon  = "/emojis/1f1ef-1f1f5.png"
  }
  option {
    name  = "Chicago, Illinois (US)"
    value = "ord"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "Seattle, Washington (US)"
    value = "sea"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "Singapore"
    value = "sin"
    icon  = "/emojis/1f1f8-1f1ec.png"
  }
  option {
    name  = "Sydney, Australia"
    value = "syd"
    icon  = "/emojis/1f1e6-1f1fa.png"
  }
  option {
    name  = "Toronto, Canada"
    value = "yyz"
    icon  = "/emojis/1f1e8-1f1e6.png"
  }
}

data "coder_parameter" "fly-org" {
  name        = "Fly.io Organization"
  description = "The Fly.io organization to deploy the workspace in"
  default     = "coder-409" # Replace with your own org or personal account
  icon        = "/emojis/1f3ec.png"
}

resource "coder_app" "code-server" {
  count        = 1
  agent_id     = coder_agent.main.id
  display_name = "Code Server"
  slug         = "code-server"
  url          = "http://localhost:8080?folder=/home/coder/"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:8080/healthz"
    interval  = 3
    threshold = 10
  }
}

resource "coder_agent" "main" {
  arch                   = data.coder_provisioner.me.arch
  os                     = "linux"
  login_before_ready     = false
  startup_script_timeout = 180
  startup_script         = <<-EOT
    set -e
    # Start code-server
    code-server --auth none >/tmp/code-server.log 2>&1 &
    # Set the hostname to the workspace name
    sudo hostname -b "${data.coder_workspace.me.name}-fly"
  EOT
}

data "coder_provisioner" "me" {
}

data "coder_workspace" "me" {
}



