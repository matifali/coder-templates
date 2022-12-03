# Coder OSS templates

Docker based templates.

1. [deeplearning](https://github.com/matifali/coder-templates/tree/master/deeplearning) (tensorflow + pytorch + numpy + matplotlib + pandas + conda + pip + jupyter notebbok or jupyter lab)
2. [matlab](https://github.com/matifali/coder-templates/tree/master/matlab) (You can add as many toolboxes as you wish by commneting them out in the associated [dockerfile](https://github.com/matifali/coder-templates/blob/master/matlab/images/r2022b.Dockerfile))

# Instructions

To use these templates simply clone the repo and run,
```console
git clone --recurse-submodules https://github.com/matifali/coder-templates.git
cd <template directory>
coder templates create <template name>
```
To update
```console
coder templates push <template name>
```
## Automatic updates
Update your templaets automatically by using this GitHub action.
[Update Coder Template](https://github.com/marketplace/actions/update-coder-template)
