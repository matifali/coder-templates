# Build argumnets
ARG UBUNTU_VER=22.04
# # Download the base image
FROM ubuntu:${UBUNTU_VER}

# Install as root
USER root

# Install dependencies
ARG DEBIAN_FRONTEND="noninteractive"
ARG USERNAME=coder

# Shell
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get upgrade -y && \
    APT_INSTALL="apt-get install -y --no-install-recommends" && \
    $APT_INSTALL \
    bash \
    bash-completion \
    ca-certificates \
    cmake \
    curl \
    git \
    htop \
    libopenblas-dev \
    linux-headers-$(uname -r) \
    nano \
    openssh-client \
    python3 python3-dev python3-pip python-is-python3 \
    sudo \
    unzip \
    vim \
    wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb && \
    apt-get install -y ./cuda-keyring_1.0-1_all.deb && \
    rm cuda-keyring_1.0-1_all.deb

RUN apt-get update && \
    apt-get install -y --no-install-recommends cuda && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get upgrade -y && \
    APT_INSTALL="apt-get install -y --no-install-recommends" && \
    $APT_INSTALL \
    libcudnn8 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add a user `${USERNAME}` so that you're not developing as the `root` user
RUN useradd ${USERNAME} \
    --uid=1000 \
    --create-home \
    --shell=/bin/bash \
    --user-group && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

# Python version
ARG PYTHON_VER=3.10

# Install miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /opt/miniconda.sh && \
    /bin/bash /opt/miniconda.sh -b -p /opt/miniconda && \
    groupadd conda && chgrp -R conda /opt/miniconda && chmod 770 -R /opt/miniconda && adduser ${USERNAME} conda && \
    rm -rf /opt/miniconda.sh && \
    echo ". /opt/miniconda/etc/profile.d/conda.sh" >> /home/${USERNAME}/.profile

# Change to your user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Put conda in path so we can use conda activate
ENV PATH=/opt/miniconda/bin:$PATH

# Initialize and update conda
RUN conda init bash && \
    # Enable bash-completion
    sudo wget --quiet https://github.com/tartansandal/conda-bash-completion/raw/master/conda -P /etc/bash_completion.d/ && \
    # Create deep-learning environment
    conda update --name base --channel conda-forge conda && \
    conda install mamba -n base -c conda-forge && \
    mamba init && \
    source /home/${USERNAME}/.bashrc && \
    rm /opt/miniconda/pkgs/cache/*.json && \
    mamba create --name DL --channel conda-forge python=${PYTHON_VER} --yes && \
    mamba clean -a -y && \
    # Make new shells activate the DL environment:
    echo "# Make new shells activate the DL environment" >> /home/${USERNAME}/.bashrc && \
    echo "conda activate DL" >> /home/${USERNAME}/.bashrc

# Install packages inside the new environment
RUN	conda activate DL && \	
    PIP_INSTALL="pip install --upgrade --no-cache-dir" && \
    $PIP_INSTALL pip && \
    $PIP_INSTALL pybind11 scikit-build && \
    $PIP_INSTALL torch torchvision torchaudio torchtext --extra-index-url https://download.pytorch.org/whl/cu116 && \
    $PIP_INSTALL \
    Cython \
    intel-openmp \
    ipywidgets \
    jupyterlab \
    matplotlib \
    mkl \
    nltk \
    notebook \
    numpy \
    pandas \
    Pillow \
    plotly \
    pytest \
    PyYAML \
    scipy \
    scikit-image \
    scikit-learn \
    sympy \
    seaborn \
    tensorflow \
    tqdm \
    wheel \
    && \
    pip cache purge && \
    # Set path of python packages
    echo "# Set path of python packages" >> /home/${USERNAME}/.bashrc && \
    echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/${USERNAME}/.bashrc