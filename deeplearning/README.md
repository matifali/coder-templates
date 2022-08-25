# Coder Setup

Follow these steps to configure accessing your workspaces locally on any machine.

## Linux

```bash
curl -o .local/bin/coder http://ctar-ml.eee.bilkent.edu.tr:3000/bin/coder-linux-amd64 && chmod a+x .local/bin/coder
coder login http://ctar-ml.eee.bilkent.edu.tr:3000/
coder config-ssh
```

## Windows

1. Download coder executable from [http://ctar-ml.eee.bilkent.edu.tr:3000/bin/coder-windows-amd64.exe](http://ctar-ml.eee.bilkent.edu.tr:3000/bin/coder-windows-amd64.exe)

2. rename `coder-windows-amd64.exe` to `coder.exe`

3. copy `coder.exe` to `C:\Windows\` 
   or
   add `coder.exe` to `PATH`

4. Open a `powershell` window and run 

   ```powershell
   md $HOME/.ssh
   coder login http://ctar-ml.eee.bilkent.edu.tr:3000/
   coder config-ssh
   ```
   or alternatively open `cmd` and run
   
   ```cmd
   md %USERPROFILE%/.ssh
   coder login http://ctar-ml.eee.bilkent.edu.tr:3000/
   coder config-ssh
   ```


After that follow the steps as shown in console and you can connect your workspaces using ssh.

## Connecting your workspace

There are 2 options to connect to your workspace using  local clients.

### VS Code Remote

Once you've configured SSH, you can work on projects from your local copy of VS Code, connected to your Coder workspace for compute, etc.

1. Open [VS Code](https://code.visualstudio.com/download) locally.
2. Install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension.
3. In VS Code's left-hand nav bar, click **Remote Explorer** and right-click on a workspace to connect.

### Jetbrains Gatway

JetBrains (with [Gateway](https://www.jetbrains.com/help/idea/remote-development-a.html#launch_gateway) installed)

- IntelliJ IDEA
- CLion
- GoLand
- PyCharm
- Rider
- RubyMine
- WebStorm
