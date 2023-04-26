terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~>0.7.0"
    }
    heroku = {
      source  = "heroku/heroku"
      version = "~>5.2.1"
    }
  }
}

variable "heroku_api_key" {
  type        = string
  description = <<-EOT
    The Heroku API key to use for authentication. You can generate one by either:
        Heroku Dashboard → Account Settings → Applications → Authorizations
    or by running the
        `heroku auth` command of the Heroku CLI.
    EOT
  sensitive   = true
}

provider "heroku" {
  api_key = var.heroku_api_key
}

provider "coder" {
  feature_use_managed_variables = true
}

resource "heroku_app" "workspace" {
  count = data.coder_workspace.me.start_count
  name  = join("-", ["coder", data.coder_workspace.me.owner, data.coder_workspace.me.name, substr(data.coder_workspace.me.id, 0, 8)])
  # name   = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-${data.coder_workspace.me.id}"
  region = data.coder_parameter.region.value
  stack  = "container"
  config_vars = {
    CODER_AGENT_TOKEN = coder_agent.main.token
    ACCESS_URL        = "${data.coder_workspace.me.access_url}/"
    ARCH              = data.coder_provisioner.me.arch
    AUTH_TYPE         = coder_agent.main.auth
  }
}

resource "heroku_build" "workspace" {
  count  = data.coder_workspace.me.start_count
  app_id = heroku_app.workspace[count.index].id
  source {
    path = "build"
  }
}

resource "heroku_formation" "workspace" {
  count      = data.coder_workspace.me.start_count
  app_id     = heroku_app.workspace[count.index].id
  type       = "worker"
  size       = data.coder_parameter.size.value
  quantity   = 1
  depends_on = [heroku_build.workspace]
}

data "coder_parameter" "region" {
  name         = "region"
  display_name = "Region"
  description  = "Choose region"
  type         = "string"
  icon         = "/emojis/1f30e.png"
  mutable      = false
  default      = "us"
  option {
    name  = "United States"
    value = "us"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "Europe"
    value = "eu"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
}


data "coder_parameter" "size" {
  name         = "size"
  display_name = "Formation Size"
  description  = "Choose formation size"
  type         = "string"
  mutable      = false
  default      = "standard-1x"
  option {
    name  = "Basic"
    value = "basic"
  }
  option {
    name  = "Standard-1x"
    value = "standard-1x"
  }
  option {
    name  = "Standard-2x"
    value = "standard-2x"
  }
  option {
    name  = "Performance-M"
    value = "performance-m"
  }
  option {
    name  = "Performance-L"
    value = "performance-l"
  }
}

resource "coder_app" "code-server" {
  count        = 1
  agent_id     = coder_agent.main.id
  display_name = "Code Server"
  slug         = "code-server"
  url          = "http://localhost:13337?folder=/home/coder/"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
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
    echo "Starting code-server..."
    code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
  EOT
}

resource "coder_metadata" "workspace" {
  count       = data.coder_workspace.me.start_count
  resource_id = heroku_app.workspace[count.index].id
  icon        = data.coder_parameter.region.option[index(data.coder_parameter.region.option.*.value, data.coder_parameter.region.value)].icon
  item {
    key   = "Region"
    value = data.coder_parameter.region.option[index(data.coder_parameter.region.option.*.value, data.coder_parameter.region.value)].name
  }
  item {
    key   = "Instance Size"
    value = data.coder_parameter.size.option[index(data.coder_parameter.size.option.*.value, data.coder_parameter.size.value)].name
  }
}

data "coder_provisioner" "me" {
}

data "coder_workspace" "me" {
}
