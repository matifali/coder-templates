# Coder Setup

Follow these steps to configure accessing your workspaces locally on any machine.

## Linux/MacOS

1. Open a terminal and run

   ```bash
   curl -L https://coder.com/install.sh | sh
   
   coder login https://coder.your-domain.com:3000/
   
   coder config-ssh
   ```

## Windows

1. Download coder executable from [https://coder.your-domain.com:3000/bin/coder-windows-amd64.exe](https://coder.your-domain.com:3000/bin/coder-windows-amd64.exe)

2. rename `coder-windows-amd64.exe` to `coder.exe`

3. copy `coder.exe` to `C:\Windows\` 
   or
   add `coder.exe` to `PATH`

4. Open a `powershell` window and run 

   ```powershell
   md $HOME/.ssh
   coder login https://coder.your-domain.com:3000/
   coder config-ssh
   ```

   or alternatively open `cmd` window and run

   ```cmd
   md %USERPROFILE%/.ssh
   coder login https://coder.your-domain.com:3000/
   coder config-ssh
   ```

After that follow the steps as shown in console and you can connect your workspaces using ssh.

# Connecting

There are multiple ways to connect to your workspace

## Browser

Click on the **Matlab** icon to launch a matlab instant in your browser

![](/home/atif/coder/templates/matlab/matlab_connect.png)

Also, you can connect using the **Web Terminal** or **SSH** by clicking on the above buttons.