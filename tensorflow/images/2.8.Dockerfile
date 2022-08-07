FROM tensorflow/tensorflow:2.8.2-gpu-jupyter
USER root
RUN apt update
RUN apt upgrade -y
RUN apt install -y curl sudo


ARG USERNAME
# Add a user `coder` so that you're not developing as the `root` user
RUN useradd ${USERNAME} \
    --create-home \
    --shell=/bin/bash \
    --uid=1000 \
    --user-group && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER ${USERNAME}
