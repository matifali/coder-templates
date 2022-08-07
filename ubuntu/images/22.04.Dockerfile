FROM ubuntu:22.04
USER root
RUN apt update
RUN apt upgrade -y
RUN apt install -y curl sudo wget bash-completion python3 python-is-python3


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

USER ${USERNAME}
