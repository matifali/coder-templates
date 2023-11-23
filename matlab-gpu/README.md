---
name: Matlab
description: Use this template to create a matlab workspace with browser based matlab instant.
tags: [matlab, noVNC, webapp, browser. desktop, docker]
icon: https://raw.githubusercontent.com/matifali/logos/main/matlab.svg
---

# Coder template matlab

A matlab template for [coder](https://coder.com/).

## Usage

1. Clone this repository

   ```bash
   git clone https://github,com/matifali/coder-templates
   cd coder-templates/matlab-gpu
   ```

2. Login to coder

   ```bash
   coder login CODER_URL
   ```

   > Replace coder.example.com with your coder deployment URL or IP

3. Create a template

   ```bash
   coder templates create matlab-gpu
   ```

4. Create a workspace

   ```bash
   coder create matlab --template matlab-gpu
   ```

   Or,
   Go to `https://CODER_URL/workspaces` and click on **Create Workspace** and select **matlab** template.

> Note: Do not forget to change the `CODER_URL` to your coder deployment URL.

## Connecting

There are multiple ways to connect to your workspace

1. Click on the **Matlab Desktop** icon to launch a matlab instant in your browser using noVNC.
2. Click on the **Matlab Browser** icon to launch a matlab instant in your browser using matlab web app.

![matlab-connect-image](./matlab_connect.png)

Also, you can connect using the **Web Terminal** or **SSH** by clicking on the above buttons.

## Docker Image

- dockerhub: https://hub.docker.com/repository/docker/matifali/matlab/general
- Source: https://github.com/matifali/matlab
