FROM tensorflow/tensorflow:latest-gpu-jupyter
USER root
RUN apt update
RUN apt upgrade -y
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
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
    --uid=1000 \
    --user-group && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

# Change to your user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install python packages as your user
RUN pip install --upgrade pip
RUN pip install torch torchvision torchaudio torchtext --extra-index-url https://download.pytorch.org/whl/cu116
RUN pip install \
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
