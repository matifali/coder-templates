# Coder [^1] OSS templates

Docker-based templates.

1. [deeplearning](https://github.com/matifali/coder-templates/tree/master/deeplearning) (`tensorflow` + `pytorch` + `numpy` + `matplotlib` + `pandas` + `conda` + `pip` + `jupyter`)
2. [deeplearning-nvidia](https://github.com/matifali/coder-templates/tree/master/deeplearning-nvidia) (Nvidia NGC containers)
3. [matlab](https://github.com/matifali/coder-templates/tree/master/matlab) (MATLAB docker images)

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

Create a GitHub workflow to automatically update the templates. Use the **Update Coder Template**[^2] action.

## Deeplearning Images

Deeplearning images used in the template are available at dockerhub[^3].

Source code of deeplearning images is available here[^4].

## MATLAB Image

MATLAB images used in the template is available at dockerhub[^5].

Source code for the matlab docker image is available here[^6].

## Contributing

Contributions are welcome. Please open an issue or a pull request. Thanks!

## License

[MIT](./LICENSE)

## Credits

[^1]: [Coder](https://github.com/coder/coder)
[^2]: [Update Coder Template](https://github.com/marketplace/actions/update-coder-template)
[^3]: [dockerdl images](https://hub.docker.com/repository/docker/matifali/dockerdl)
[^4]: [dockerdl source](https://github.com/matifali/dockerdl)
[^5]: [matlab images](https://hub.docker.com/repository/docker/matifali/matlab)
[^6]: [matlab source](https://github.com/matifali/matlab)