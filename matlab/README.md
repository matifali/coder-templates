# Coder template matlab

## Connecting

There are multiple ways to connect to your workspace

1. Click on the **Matlab Desktop** icon to launch a matlab instant in your browser using noVNC.
2. Click on the **Matlab Browser** icon to launch a matlab instant in your browser using matlab web app.

![matlab-connect-image](./matlab_connect.png)

Also, you can connect using the **Web Terminal** or **SSH** by clicking on the above buttons.

## Coder Setup

Follow these steps to configure accessing your workspaces locally on any machine.

### Linux/MacOS

1. Open a terminal and run

   ```bash
   curl -L https://coder.com/install.sh | sh
   
   coder login https://gpu.ctar.ml
   
   coder config-ssh
   ```

### Windows

1. Download coder executable from <https://gpu.ctar.ml/bin/coder-windows-amd64.exe>

2. rename `coder-windows-amd64.exe` to `coder.exe`

3. copy `coder.exe` to `C:\Windows\`
   or
   add `coder.exe` to `PATH`

4. Open a `powershell` window and run

   ```powershell
   md $HOME/.ssh
   coder login https://gpu.ctar.ml
   coder config-ssh
   ```

   or alternatively open `cmd` window and run

   ```cmd
   md %USERPROFILE%/.ssh
   coder login https://gpu.ctar.ml
   coder config-ssh
   ```

## Persistent Storage

There will be a `~/data` inside every workspace. All files placed here will survive reboots and be available to all workspaces.

To upload or download files to `~/data` go to https://share.ctar.ml
