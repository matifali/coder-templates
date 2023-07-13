ARG NGC_VERSION=23.06
FROM nvcr.io/nvidia/tensorflow:${NGC_VERSION}-tf2-py3

# Install extra packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    htop \
    nvidia-modprobe \
    sudo \
    tmux \
    && \
    rm -rf /var/lib/apt/lists/

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
ENV PATH=/home/${USERNAME}/.local/bin:$PATH
WORKDIR /home/${USERNAME}
