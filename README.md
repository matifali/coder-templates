# Coder OSS templates

Docker based templates.

1. [deeplearning](https://github.com/matifali/coder-templates/tree/master/deeplearning) (tensorflow + pytorch + numpy + matplotlib + pandas + conda + pip + jupyter notebook or jupyter lab + Microsoft code-server)
2. [deeplearning-nvidia](https://github.com/matifali/coder-templates/tree/master/deeplearning-nvidia) (Nvidia NGC containers)
3. [matlab](https://github.com/matifali/coder-templates/tree/master/matlab) (MATLAB docker images)

## Pre-requisites

[Coder](github.com/coder/coder) deployment set up on `CODER_URL` (e.g. https://coder.example.com)

## Installation

### Linux / MacOS

1. Open a terminal and run

   ```bash
   curl -L https://coder.com/install.sh | sh
   ```

### Windows

1. Open a `powershell` window and run

   ```powershell
   winget install Coder.Coder
   ```

## Instructions

To use these templates simply clone the repo and run,

```console
git clone https://github.com/matifali/coder-templates.git
cd <template directory>
coder templates create <template-name>
```

## Updates

### Manual

To update manually,

```console
coder templates push <template-name>
```

### Automatic

Set up the following Github secrets in your repo.

1. `CODER_ACCESS_TOKEN` - Coder access token

   To create a token with life of 1 year, run,

   ```shell
   coder tokens create --lifetime 8760h0m0s
   ```

2. `CODER_URL` - Coder deployment url (e.g. https://coder.example.com)

## Deeplearning Images

Deeplearning images used in the template are available at [dockerhub](https://hub.docker.com/repository/docker/matifali/dockerdl).

Source code of deeplearning images is available at, [https://github.com/matifali/dockerdl](https://github.com/matifali/dockerdl)

## MATLAB Image

MATLAB images used in the template is available at [dockerhub](https://hub.docker.com/repository/docker/matifali/matlab).

Source code for the matlab docker image is available at [https://github.com/matifali/matlab](https://github.com/matifali/matlab)

## Contributing

Contributions are welcome. Please open an issue or a pull request. Thanks!

## License

[MIT](./LICENSE)

## Credits

- [Coder](https://github.com/coder/coder)
- [MATLAB Docker Images](https://hub.docker.com/r/matlab/matlab)
- [Nvidia NGC containers](https://ngc.nvidia.com/catalog/containers)
- [Update Coder Template](https://github.com/marketplace/actions/update-coder-template)
