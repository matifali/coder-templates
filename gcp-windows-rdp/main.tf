terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "coder" {
  feature_use_managed_variables = "true"
}

variable "project_id" {
  description = "Which Google Compute Project should your workspace live in?"
  default     = ""
}

data "coder_parameter" "zone" {
  display_name = "GCP Zone"
  name         = "zone"
  type         = "string"
  description  = "What GCP zone should your workspace live in?"
  mutable      = false
  default      = "us-central1-a"
  icon         = "/emojis/1f30e.png"

  option {
    name  = "US NorthEast 1"
    value = "northamerica-northeast1-a"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US Central 1"
    value = "us-central1-a"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US West 2"
    value = "us-west2-c"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "Europe West 4"
    value = "europe-west4-b"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "South America East 1"
    value = "southamerica-east1-a"
    icon  = "/emojis/1f1e7-1f1f7.png"
  }

}

data "coder_parameter" "machine-type" {
  display_name = "GCP machine type"
  name         = "machine-type"
  type         = "string"
  description  = "GCP machine type"
  mutable      = false
  default      = "e2-medium"

  option {
    name  = "e2-standard-4"
    value = "e2-standard-4"
  }
  option {
    name  = "e2-standard-2"
    value = "e2-standard-2"
  }
  option {
    name  = "e2-medium"
    value = "e2-medium"
  }
  option {
    name  = "e2-micro"
    value = "e2-micro"
  }
  option {
    name  = "e2-small"
    value = "e2-small"
  }

}

data "coder_parameter" "os" {
  name         = "os"
  display_name = "Windows OS"
  type         = "string"
  description  = "Release of Microsoft Windows Server"
  mutable      = false
  default      = "windows-server-2022-dc-v20230414"

  option {
    name  = "2022"
    value = "windows-server-2022-dc-v20230414"
  }
  option {
    name  = "2019"
    value = "windows-server-2019-dc-v20230414"
  }
}

provider "google" {
  zone        = data.coder_parameter.zone.value
  project     = var.project_id
  credentials = file("/home/coder/.config/gcloud/application_default_credentials.json")
}

data "google_compute_default_service_account" "default" {

}

data "coder_workspace" "me" {
}

resource "google_compute_disk" "root" {
  name  = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-root"
  type  = "pd-ssd"
  zone  = data.coder_parameter.zone.value
  image = "projects/windows-cloud/global/images/${data.coder_parameter.os.value}"
  lifecycle {
    ignore_changes = [image]
  }
}

resource "coder_agent" "main" {
  auth               = "google-instance-identity"
  arch               = "amd64"
  connection_timeout = 300 # the first boot takes some time
  os                 = "windows"
  login_before_ready = false
  startup_script     = <<EOF

# Set admin password and enable admin user (must be in this order)
Get-LocalUser -Name "Administrator" | Set-LocalUser -Password (ConvertTo-SecureString -AsPlainText "${local.admin_password}" -Force)
Get-LocalUser -Name "Administrator" | Enable-LocalUser

# Enable RDP
New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -PropertyType DWORD -Force

# Disable NLA
New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer" -Value 1 -PropertyType DWORD -Force

# Enable RDP through Windows Firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

choco feature enable -n=allowGlobalConfirmation

# Install Myrtille
echo "Downloading Myrtille"
New-Item -ItemType Directory -Force -Path C:\temp
Invoke-WebRequest -Uri "https://github.com/cedrozor/myrtille/releases/download/v2.9.2/Myrtille_2.9.2_x86_x64_Setup.msi" -Outfile c:\temp\myrtille.msi
echo "Download complete"
echo "Installing Myrtille"
Start-Process C:\temp\myrtille.msi -ArgumentList "/quiet"
echo "Intallation complete"

# echo "Starting Myrtille"
# Workaround for myrtile not starting automatically
while (!(Test-Path C:\inetpub\wwwroot\iisstart.htm)) {
  # New-Item -ItemType File -Force -Path C:\inetpub\wwwroot\iisstart.htm
  echo "waiting for myrtille to start"
  Start-Sleep -s 10
}
"<head>
  <meta http-equiv='refresh' content='0; URL=https://${local.redirect_url_1}${local.redirect_url_2}${local.redirect_url_3}'>
</head>" | Out-File -FilePath C:\inetpub\wwwroot\iisstart.htm

echo "Startup script complete"

EOF
}

locals {
  admin_password = "coderRDP!"
  redirect_url_1 = "rdp--main--${lower(data.coder_workspace.me.name)}--${lower(data.coder_workspace.me.owner)}."
  redirect_url_2 = split("//", data.coder_workspace.me.access_url)[1]
  redirect_url_3 = "/Myrtille/?__EVENTTARGET=&__EVENTARGUMENT=&server=localhost&user=Administrator&password=${local.admin_password}&connect=Connect%21"
  # redirect_url   = "https://${local.redirect_url_1}${local.redirect_url_2}${local.redirect_url_3}"
}

resource "google_compute_instance" "dev" {
  zone         = data.coder_parameter.zone.value
  count        = data.coder_workspace.me.start_count
  name         = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
  machine_type = data.coder_parameter.machine-type.value
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  boot_disk {
    auto_delete = false
    source      = google_compute_disk.root.name
  }
  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata = {

    windows-startup-script-ps1 = <<EOF

    # Install Chocolatey package manager before
    # the agent starts to use via startup_script
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    # Reload path so sessions include "choco" and "refreshenv"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    # Install Git and reload path
    choco install -y git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    # start Coder agent init script (see startup_script above)
    ${coder_agent.main.init_script}

    EOF

  }
}

resource "coder_app" "rdp" {
  agent_id     = coder_agent.main.id
  display_name = "RDP Desktop"
  slug         = "rdp"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/windows.svg"
  url          = "http://localhost"
  subdomain    = true
  share        = "owner"
  healthcheck {
    url       = "http://localhost"
    interval  = 3
    threshold = 120
  }
}


resource "coder_app" "rdp-docs" {
  agent_id     = coder_agent.main.id
  display_name = "How to use local RDP client"
  slug         = "rdp-docs"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/windows.svg"
  external     = "https://coder.com/docs/v2/latest/ides/remote-desktops"
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = google_compute_instance.dev[0].id
  item {
    key       = "Administrator password"
    value     = local.admin_password
    sensitive = true
  }
  item {
    key   = "zone"
    value = data.coder_parameter.zone.value
  }
  item {
    key   = "machine-type"
    value = data.coder_parameter.machine-type.value
  }
  item {
    key   = "windows os"
    value = data.coder_parameter.os.value
  }
}
