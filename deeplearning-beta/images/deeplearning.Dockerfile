#FROM ubuntu:latest
FROM codercom/enterprise-vnc:ubuntu
SHELL ["/bin/bash", "--login", "-c"]

USER root
ARG DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && apt-get upgrade -y && \
    apt-get install --yes \
    --no-install-recommends \
    bash \
    bash-completion \
    bzip2 \
    curl \
    git \
    nano \
    python3 python3-dev python3-pip python-is-python3 \
    sudo \
    unzip \
    wget \
    zip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG USERNAME=coder
# Add a user with your coder username so that you're not developing as the `root` user
RUN userdel -f -r coder && useradd ${USERNAME} \
    --create-home \
    --shell=/bin/bash \
    --uid=1001 \
    --user-group && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

# Change to your user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install miniconda
ENV CONDA_DIR /home/${USERNAME}/miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
	/bin/bash ~/miniconda.sh -b -p $CONDA_DIR && rm -rf ~/miniconda.sh

# Put conda in path so we can use conda activate
ENV PATH=$CONDA_DIR/bin:$PATH
RUN echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> ~/.profile

# Initialize and update conda
RUN conda init bash && conda update --name base --channel defaults conda

# Enable bash-completion
RUN sudo wget --quiet https://github.com/tartansandal/conda-bash-completion/raw/master/conda -P /etc/bash_completion.d/


# Install and configure micromamba
#RUN curl micro.mamba.pm/install.sh | bash
#RUN	micromamba shell completion
#RUN micromamba shell init --shell=bash --prefix=~/micromamba
#RUN eval "$(micromamba shell hook --shell=bash)"
#RUN	echo alias conda="micromamba" >> .bashrc && source .bashrc
#RUN cat .bashrc 
#&& source .bashrc

# Create deep-learning environment
RUN conda install mamba -n base -c conda-forge && mamba init && source .bashrc
RUN mamba create --name DL python=3.10 --yes

# Make RUN commands use the new environment:
RUN echo "conda activate DL" >> ~/.bashrc

# Install conda packages
RUN conda activate DL && mamba install \
	cudatoolkit=11.7 \
	cudnn \
	cmake \
	Cython \
	intel-openmp \
	Markdown \
	mkl \
	spyder -c conda-forge --yes && mamba clean -a -y && conda clean -a -y && \
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/

# Install python pip packages as your user
ARG PIP_NO_CACHE_DIR=1
RUN pip install --upgrade pip && \
	pip install torch torchvision torchaudio torchtext --extra-index-url https://download.pytorch.org/whl/cu116 && \
	pip install \
	matplotlib \
	Markdown \
	notebook \
	pandas \
	Pillow \
	PyYAML \
	scikit-learn scikit-image \
	seaborn plotly \
	tensorflow \
	tqdm
	
# Set path of python packages
RUN echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/${USERNAME}/.bashrc
