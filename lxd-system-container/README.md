---
name: LXD System Container with Docker
description: Develop in a LXC System Container with Docker using LXD
tags: [local, lxc, lxd]
icon: /icon/lxc.svg
---

# LXC VM
Develop in a LXC System Container and run nested Docker containers using LXD on your local infrastructure.

## Prerequisites

1. Install [LXD](https://canonical.com/lxd) on the same machine as Coder.
2. Allow Coder to access the LXD socket.
    - If you're running Coder as system service, run `sudo usermod -aG lxd coder` and restart the Coder service.
    - If you're running Coder as a Docker Compose service, get the group ID of the `lxd` group by running `getent group lxd` and add the following to your `compose.yaml` file:

        ```yaml
        services:
          coder:
            volumes:
              - /var/snap/lxd/common/lxd/unix.socket:/var/snap/lxd/common/lxd/unix.socket
            group_add:
              - 120 # Replace with the group ID of the `lxd` group
        ```
3. Create a storage pool named `coder` and `btrfs` as the driver by running `lxc storage create coder btrfs`.
4. Optionally enable the Web UI by running,
    
        ```bash
        lxc config set core.https_address [::]:8443
        sudo snap set lxd ui.enable=true
        sudo systemctl reload snap.lxd.daemon
        ```
        and then visit `https://<host>:8443` in your browser.

## Usage

1. clone this repo
2. run `coder templates init`
3. select this template
4. follow the on-screen instructions

## Extending this template

See the [terraform-lxd/lxd](https://registry.terraform.io/providers/terraform-lxd/lxd/latest/docs) Terraform provider documentation to
add the following features to your Coder template:

- HTTPS LXD host
- Volume mounts
- Custom networks
- More

We also welcome contributions!
