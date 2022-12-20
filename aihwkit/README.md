# Persistent Storage

After you login to the server and run `ls` to list all directories, you will see a directory named `~/data`.

This will persists reboots and will be available in all your work-spaces. It is suggested to store your training data in this directory.

# Coder Setup

Follow these steps to configure accessing your workspaces locally on any machine.

## Linux/MacOS

1. Open a terminal and run

   ```bash
   curl -L https://coder.com/install.sh | sh
   coder login https://gpu.ctar.ml
   coder config-ssh
   ```

## Windows

1. Download coder executable from [https://gpu.ctar.ml/bin/coder-windows-amd64.exe](https://gpu.ctar.ml/bin/coder-windows-amd64.exe)

2. rename `coder-windows-amd64.exe` to `coder.exe`

3. copy `coder.exe` to `C:\Windows\`
   or
   add `coder.exe` to `PATH`

4. Open a `powershell` window and run

   ```powershell
   md $HOME\.ssh
   coder login https://gpu.ctar.ml
   coder config-ssh
   ```

   or alternatively open `cmd` window and run

   ```cmd
   md %USERPROFILE%\.ssh
   coder login https://gpu.ctar.ml
   coder config-ssh
   ```

After that follow the steps as shown in console and you can connect your workspaces using ssh.

# Connecting your workspace

There are multiple options to connect to your workspace using local clients or browser.

## Jupyter Notebook

Click on the jupyter icon to launch a jupyter notebook server that you can connect from your browser.

![Workspace connect options](https://i.ibb.co/ZLCHXf1/workspace-connect.png)

Also, you can connect using the **Web Terminal** or **SSH** by clicking on the above buttons.

## VS Code Remote

Once you've configured SSH, you can work on projects from your local copy of VS Code, connected to your Coder workspace for compute, etc.

1. Open [VS Code](https://code.visualstudio.com/download) locally.

2. Install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension.

3. In VS Code's left-hand nav bar, click **Remote Explorer** and right-click on a workspace to connect.

## JetBrains PyCharm Professional

1. Install PyCharm Professional by using [JetBrains Toolbox App](https://www.jetbrains.com/toolbox-app/).

2. Connect your local machine to server via ssh by following the [instructions](https://www.jetbrains.com/help/pycharm/configuring-remote-interpreters-via-ssh.html#prereq).

## JetBrains Gateway

1. Follow the [instructions](https://coder.com/docs/coder-oss/latest/ides/gateway) here to get a fully working PyCharm IDE.

## Spyder (Remote Kernels) [Advanced]

(not tested)

1. Install [Spyder](https://docs.spyder-ide.org/current/installation.html) on your local machine.

2. Connect Spyder with external kernel by following the [instructions](https://docs.spyder-ide.org/current/panes/ipythonconsole.html#using-external-kernels).