FROM nvidia/cuda:11.7.0-devel-ubuntu22.04
USER root
RUN apt update
RUN apt upgrade -y
RUN apt install -y curl sudo wget


ARG USERNAME
# Add a user `coder` so that you're not developing as the `root` user
RUN useradd ${USERNAME} \
    --create-home \
    --shell=/bin/bash \
    --uid=1000 \
    --user-group && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

# Install coder-server 
RUN curl -fsSL https://code-server.dev/install.sh | sh
# Install vscode-extension-python
RUN code-server --install-extension ms-python.python

USER ${USERNAME}
