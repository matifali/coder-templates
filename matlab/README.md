# Coder template matlab

## Usage

1. Clone this repository

   ```bash
   git clone https://github,com/matifali/coder-templates
   cd coder-templates/matlab
   ```

2. Create a template

   ```bash
   coder templates create matlab
   ```

3. Create a workspace

   ```bash
   coder create matlab --template matlab
   ```

   Or,
   Go to <https://coder.example.com/workspaces> and click on **Create Workspace** and select **matlab** template.

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
   
   coder login https://coder.example.com
   
   coder config-ssh
   ```

### Windows

1. Download coder executable from <https://coder.example.com/bin/coder-windows-amd64.exe>

2. rename `coder-windows-amd64.exe` to `coder.exe`

3. copy `coder.exe` to `C:\Windows\`
   or
   add `coder.exe` to `PATH`

4. Open a `powershell` window and run

   ```powershell
   md $HOME/.ssh
   coder login https://coder.example.com
   coder config-ssh
   ```

   or alternatively open `cmd` window and run

   ```cmd
   md %USERPROFILE%/.ssh
   coder login https://coder.example.com
   coder config-ssh
   ```

## Persistent Storage

<https://github.com/matifali/coder-templates/blob/55dd329783eb2583be6334c950acf4fcf73e1d0f/matlab/main.tf#L136>
This is the host directory that will be mapped to `~/data` inside the workspace. make sure you set the permissions and owner ship as a user with `uid:gid` 1000. create subdirectories with the usernames of all coder users.

```console
sudo chown 1000:1000 -R your_data_dir
sudo chmod -R 755 your_data_dir
```

After this `your_data_dir/user` will be mapped to `~/data` inside every workspace. This is useful for storing persistent data as well as sharing data between workspaces. This will survive workspace restarts and image updates.

If you do not want this just remove this volume mount from `[main.tf](https://github.com/matifali/coder-templates/blob/master/matlab/main.tf)`
