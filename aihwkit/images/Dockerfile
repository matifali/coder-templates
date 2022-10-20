# Build argumnets
ARG CUDA_VER=11.8
ARG UBUNTU_VER=22.04

# Download the base image
FROM nvidia/cuda:${CUDA_VER}.1-devel-ubuntu${UBUNTU_VER}
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
    apt-get install -y --no-install-recommends \
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
    sudo \
    unzip \
    vim \
    wget \ 
    zip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Python version
ARG PYTHON_VER=3.10

# Install Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python${PYTHON_VER} \
    python${PYTHON_VER}-dev \
    python${PYTHON_VER}-venv \
    python3-pip \
    python-is-python3 && \
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

# Change to your user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install packages inside the new environment
RUN pip install --upgrade --no-cache-dir pip && \
    pip install --upgrade --no-cache-dir torch torchvision torchaudio torchtext --extra-index-url https://download.pytorch.org/whl/cu116
RUN pip install --upgrade --no-cache-dir \
    Cython \
    intel-openmp \
    ipywidgets \
    jupyterlab \
    matplotlib \
    mkl \
    nltk \
    numpy \
    pandas \
    Pillow \
    plotly \
    pybind11 \
    pytest \
    PyYAML \
    protobuf==3.20.2 \  
    scipy \
    scikit-build \
    scikit-image \
    scikit-learn \
    seaborn \
    tqdm

# Set path of python packages
RUN echo "# Set path of python packages" >> /home/${USERNAME}/.bashrc && \
    echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/${USERNAME}/.bashrc

# Install AIHWKIT
RUN git clone https://github.com/matifali/aihwkit.git
WORKDIR /home/${USERNAME}/aihwkit
RUN CUDA_ARCH=86 && \
    pip install . \
    --install-option="-DUSE_CUDA=ON" \
    --install-option="-DRPU_CUDA_ARCHITECTURES="${CUDA_ARCH}"" \
    --install-option="-DRPU_BLAS=OpenBLAS"
WORKDIR /home/${USERNAME}
RUN rm -rf aihwkit