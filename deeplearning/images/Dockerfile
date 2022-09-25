# Build argumnets
ARG CUDA_VER=11.7
ARG UBUNTU_VER=22.04

# Download the base image
FROM nvidia/cuda:${CUDA_VER}.1-cudnn8-runtime-ubuntu${UBUNTU_VER}
# you can check for all available images at https://hub.docker.com/r/nvidia/cuda/tags

# Install as root
USER root

# Install dependencies
ARG DEBIAN_FRONTEND="noninteractive"
ARG USERNAME=coder

# Shell
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# miniconda path
ENV CONDA_DIR /opt/miniconda

# Install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    APT_INSTALL="apt-get install -y --no-install-recommends" && \
    $APT_INSTALL \
    bash \
    bash-completion \
    ca-certificates \
    curl \
    git \
    htop \
    nano \
    openssh-client \
    sudo \
    unzip \
    vim \
    wget \ 
    zip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Install miniconda
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    /bin/bash miniconda.sh -b -p ${CONDA_DIR} && \
    rm -rf miniconda.sh && \
    # Enable conda autocomplete
    sudo wget --quiet https://github.com/tartansandal/conda-bash-completion/raw/master/conda -P /etc/bash_completion.d/

# Add a user `${USERNAME}` so that you're not developing as the `root` user
RUN useradd ${USERNAME} \
    --uid=1000 \
    --create-home \
    --shell=/bin/bash \
    --user-group && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd && \
    # Allow running conda as the new user
    groupadd conda && chgrp -R conda ${CONDA_DIR} && chmod 755 -R ${CONDA_DIR} && adduser ${USERNAME} conda && \
    echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> /home/${USERNAME}/.profile

# Put conda in path so we can use conda activate
ENV PATH=${CONDA_DIR}/bin:$PATH

# Initialize and update conda
RUN conda update --name base --channel conda-forge conda && \
    conda install mamba -n base -c conda-forge && \
    # clean up
    conda clean --all --yes

# Python version
ARG PYTHON_VER=3.10

# Change to your user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN conda init bash && \
    mamba init && \
    source /home/${USERNAME}/.bashrc && \
    # Create deep-learning environment
    mamba create --name DL --channel conda-forge python=${PYTHON_VER} --yes && \
    mamba clean -a -y && \
    # Make new shells activate the DL environment:
    echo "# Make new shells activate the DL environment" >> /home/${USERNAME}/.bashrc && \
    echo "conda activate DL" >> /home/${USERNAME}/.bashrc

# Default TensorFlow package version
ARG TF_VERSION=2.9.2

# Install packages inside the new environment
RUN conda activate DL && \	
    PIP_INSTALL="pip install --upgrade --no-cache-dir" && \
    $PIP_INSTALL pip && \
    $PIP_INSTALL pybind11 scikit-build && \
    $PIP_INSTALL torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu116 && \
    $PIP_INSTALL \
    ipywidgets \
    jupyterlab \
    matplotlib \
    nltk \
    notebook \
    numpy \
    pandas \
    Pillow \
    plotly \
    PyYAML \
    scipy \
    scikit-image \
    scikit-learn \
    sympy \
    seaborn \
    tensorflow${TF_VERSION:+==${TF_VERSION}} \
    tqdm && \
    pip cache purge && \
    # Set path of python packages
    echo "# Set path of python packages" >> /home/${USERNAME}/.bashrc && \
    echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/${USERNAME}/.bashrc