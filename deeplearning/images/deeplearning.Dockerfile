FROM tensorflow/tensorflow:latest-gpu-jupyter
USER root
ARG DEBIAN_FRONTEND="noninteractive"
RUN apt update && apt upgrade -y && \
    apt-get install --yes \
    --no-install-recommends \
    bash \
    bash-completion \
    curl \
    git \
    nano \
    python3 python3-dev python3-pip python-is-python3 \
    sudo \
    wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG USERNAME
# Add a user with your coder username so that you're not developing as the `root` user
RUN useradd ${USERNAME} \
    --create-home \
    --shell=/bin/bash \
    --uid=1001 \
    --user-group && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

# Change to your user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

ARG PIP_NO_CACHE_DIR=1
# Install python packages as your user
RUN pip install --upgrade pip && \
	pip install torch torchvision torchaudio torchtext --extra-index-url https://download.pytorch.org/whl/cu116 && \
	pip install \
	cmake \
	Cython \
	intel-openmp \
	matplotlib \
	Markdown \
	mkl \
	pandas \
	Pillow \
	PyYAML \
	scikit-learn scikit-image \
	seaborn plotly \
	tqdm
	
# Set path of python packages
RUN echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/${USERNAME}/.bashrc
