terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.3"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.23.0"
    }
  }
}

provider "coder" {}
data "coder_workspace" "me" {}

resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "linux"

  env = {
    "VSCODE_QUALITY" = "stable",
    "VSCODE_TELEMETRY_LEVEL" = "off",
    "SUPERVISOR_DIR" = "/usr/share/basic-env/supervisor"
  }

  startup_script = <<EOT
#!/bin/bash
set -e
# create users data directory
mkdir -p ~/data
# start supervisor
supervisord
# start code-server
echo "[+] Starting code-server"
supervisorctl start code-server
# start VNC server
echo "[+] Starting VNC"
echo "coder" | tightvncpasswd -f > $HOME/.vnc/passwd
supervisorctl start vnc:*
EOT
}

resource "coder_app" "supervisor" {
  agent_id = coder_agent.dev.id

  display_name = "Supervisor"
  slug         = "supervisor"

  url      = "http://localhost:8079"
  icon     = "/icon/widgets.svg"

  subdomain = "false"
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id

  display_name = "VSCode"
  slug         = "code-server"

  url      = "http://localhost:8000/?folder=/home/coder/data"
  icon     = "/icon/code.svg"

  subdomain = "false"
}

resource "coder_app" "novnc" {
  count    = 1
  agent_id = coder_agent.dev.id

  display_name = "noVNC"
  slug         = "novnc"

  url      = "http://localhost:8081?autoconnect=1&resize=scale&path=@${data.coder_workspace.me.owner}/${data.coder_workspace.me.name}.dev/apps/noVNC/websockify&password=coder"
  icon     = "/icon/novnc.svg"

  subdomain = "false"
}

resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-home"
}

resource "coder_metadata" "home" {
  resource_id = docker_volume.home.id
  hide = true
  item {
    key = "name"
    value = "home"
  }
}

resource "docker_image" "basic_env" {
  name = "matifali/ubuntu-novnc:latest"

  build {
    path = "./docker"
    tag  = ["matifali/ubuntu-novnc", "matifali/ubuntu-novnc:latest"]
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "docker/*") : filesha1(f)]))
  }

  keep_locally = true
}

resource "coder_metadata" "basic_env" {
  resource_id = docker_image.basic_env.id

  hide = true

  item {
    key   = "name"
    value = "basic_env"
  }
}

resource "docker_container" "workspace" {
  volumes {
    container_path = "/home/coder/"
    volume_name    = docker_volume.home.name
    read_only      = false
  }

  volumes {
    container_path = "/home/coder/data/"
    host_path      = "/data/${data.coder_workspace.me.owner}/"
    read_only      = false
  }

  count = data.coder_workspace.me.start_count
  image = docker_image.basic_env.image_id

  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)

  dns      = ["1.1.1.1"]

  entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}"]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
}
