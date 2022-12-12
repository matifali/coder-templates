# Coder OSS templates

Docker based templates.

1. [deeplearning](https://github.com/matifali/coder-templates/tree/master/deeplearning) (tensorflow + pytorch + numpy + matplotlib + pandas + conda + pip + jupyter notebook or jupyter lab + Microsoft code-server)
2. [matlab](https://github.com/matifali/coder-templates/tree/master/matlab) (You can add as many toolboxes as you wish by commenting them out in the associated [dockerfile](https://github.com/matifali/coder-templates/blob/master/matlab/images/r2022b.Dockerfile))

## Instructions

To use these templates simply clone the repo and run,

```console
git clone https://github.com/matifali/coder-templates.git
cd <template directory>
coder templates create <template name>
```

To update

```console
coder templates push <template name>
```

## Automatic updates

Update your templates automatically by using this GitHub action.
[Update Coder Template](https://github.com/marketplace/actions/update-coder-template)

## Deeplearning Images

Deeplearning images used in the template are available at [dockerhub](https://hub.docker.com/repository/docker/matifali/dockerdl).

Source code of deeplearning images is available at, [https://github.com/matifali/dockerdl](https://github.com/matifali/dockerdl)

## MATLAB Image

MATLAB images used in the template is available at [dockerhub](https://hub.docker.com/repository/docker/matifali/matlab).

Source code for the matlab docker image is available at  [https://github.com/matifali/matlab](https://github.com/matifali/matlab)
