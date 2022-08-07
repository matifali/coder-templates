FROM pytorch/pytorch:1.11.0-cuda11.3-cudnn8-runtime

USER root
RUN apt update
RUN apt upgrade -y
RUN apt install -y curl sudo

# Add a user `coder` so that you're not developing as the `root` user
RUN useradd coder \
    --create-home \
    --shell=/bin/bash \
    --uid=1000 \
    --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

# Install coder-server 
RUN curl -fsSL https://code-server.dev/install.sh | sh
# Install vscode-extension-python
RUN code-server --install-extension ms-python.python

USER coder