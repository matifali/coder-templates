ARG NGC_VERSION=23.02
FROM nvcr.io/nvidia/tensorflow:${NGC_VERSION}-tf2-py3

# Install extra packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        curl \
        tmux \
        && \
    rm -rf /var/lib/apt/lists/

# Install filebrowser
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# Install Microsoft VS Code Server
RUN wget -O- https://aka.ms/install-vscode-server/setup.sh | sh

# Add a user `${USERNAME}` so that you're not developing as the `root` user
ARG USERID=1000
ARG GROUPID=1000
ARG USERNAME=coder
RUN groupadd -g ${GROUPID} ${USERNAME} && \
    useradd ${USERNAME} \
    --create-home \
    --uid ${USERID} \
    --gid ${GROUPID} \
    --shell=/bin/bash && \
echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER ${USERNAME}
WORKDIR /home/${USERNAME}
