# Coder Deeplearning Template

A deeplearning template for [coder](https://coder.com/).

## Coder Setup

Follow these steps to configure accessing your workspaces locally on any machine.

### Linux/MacOS

1. Open a terminal and run

   ```bash
   curl -L https://coder.com/install.sh | sh
   ```

### Windows

1. Open a `powershell` window and run

   ```powershell
   winget install Coder.Coder
   ```
   
## Usage

1. Clone this repository

   ```bash
   git clone https://github,com/matifali/coder-templates
   cd coder-templates/deeplearning
   ```
2. Login to coder

   ```bash
   coder login coder.example.com
   ```
   > Replace coder.example.com with your coder deplyment URL or IP


3. Create a template

   ```bash
   coder templates create deeplearning
   ```

4. Create a workspace

   Go to <https://coder.example.com/workspaces> and click on **Create Workspace** and select **matlab** template.

## Connecting

There are multiple options to connect to your workspace using local clients or browser.
![deeplearning-connect](./deeplearning-connect.png)

### VS Code Server

Click on the VS Code icon to launch a VS Code server that you can connect from your browser.

### Jupyter Notebook

Click on the jupyter icon to launch a jupyter notebook server that you can connect from your browser.

Also, you can connect using the **Web Terminal** or **SSH** by clicking on the above buttons.

### VS Code Remote

Once you've configured SSH, you can work on projects from your local copy of VS Code, connected to your Coder workspace for compute, etc.

1. Open [VS Code](https://code.visualstudio.com/download) locally.
2. Install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension.
3. In VS Code's left-hand nav bar, click **Remote Explorer** and right-click on a workspace to connect.

### JetBrains PyCharm Professional

1. Install PyCharm Professional by using [JetBrains Toolbox App](https://www.jetbrains.com/toolbox-app/).
2. Connect your local machine to server via ssh by following the [instructions](https://www.jetbrains.com/help/pycharm/configuring-remote-interpreters-via-ssh.html#prereq) here.

### JetBrains Gateway

1. Follow the [instructions](https://coder.com/docs/coder-oss/latest/ides/gateway) here to get a fully working PyCharm IDE.

### Spyder (Remote Kernels) [Advanced]

(not tested)

1. Install [Spyder](https://docs.spyder-ide.org/current/installation.html) on your local machine.
2. Connect Spyder with external kernel by following the [instructions](https://docs.spyder-ide.org/current/panes/ipythonconsole.html#using-external-kernels) here.

## Persistent Storage

<https://github.com/matifali/coder-templates/blob/f6429fe2fc54a8de89621e118c68bf5cd97c003e/deeplearning/main.tf#L136>
This is the host directory that will be mapped to `~/data` inside the workspace. make sure you set the permissions and owner ship as a user with `uid:gid` 1000. create subdirectories with the usernames of all coder users.

```console
sudo chown 1000:1000 -R your_data_dir
sudo chmod -R 755 your_data_dir
```

After this `your_data_dir/user` will be mapped to `~/data` inside every workspace.

If you do not want this just remove this volume mount from [`main.tf`](./main.tf)

This will persists reboots and will be available in all your work-spaces. It is suggested to store your training data in this directory.

## Docker Images

Deeplearning images used in the template are available at [dockerhub](https://hub.docker.com/repository/docker/matifali/dockerdl).

Source code of deeplearning images is available at, [https://github.com/matifali/dockerdl](https://github.com/matifali/dockerdl)
