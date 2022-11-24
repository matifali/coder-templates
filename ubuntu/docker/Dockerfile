FROM ubuntu:latest

USER root

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt update -y && \
apt install -y apt-transport-https software-properties-common wget && \
rm -rf /var/lib/apt/lists/*

# Git
RUN add-apt-repository ppa:git-core/ppa -y

# Basic tools
RUN apt update && apt install -y --no-install-recommends \
build-essential curl git \
man locales vim htop \
bash bash-completion \
python3 python3-pip \
ca-certificates \
zip unzip \
sudo && \
rm -rf /var/lib/apt/lists/*

# X11 / VNC
RUN apt update && apt install -y --no-install-recommends \
xfonts-base xfonts-100dpi xfonts-scalable \
dbus-x11 x11-xserver-utils x11-utils \
xfce4 xfce4-goodies \
psmisc xdg-utils \
tigervnc-standalone-server tightvncpasswd \
autocutsel websockify supervisor && \
rm -rf /var/lib/apt/lists/*

# Create user coder
RUN useradd coder --create-home --shell=/bin/bash --uid=1000 --user-group && \
echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

# Install Microsoft's code-server
RUN wget -O- https://aka.ms/install-vscode-server/setup.sh | sh

ADD basic-env /usr/share/basic-env
WORKDIR /usr/share/basic-env

RUN rm -rf /etc/supervisor && \
ln -s /usr/share/basic-env/supervisor /etc/supervisor

# noVNC
RUN git clone https://github.com/novnc/noVNC && \
mv noVNC/vnc.html noVNC/index.html

RUN chown coder:coder /usr/share/basic-env -R && \
chmod 755 /usr/share/basic-env -R

USER 1000
WORKDIR /home/coder

# VNC
RUN mkdir .vnc && \
touch .vnc/passwd && \
chmod 600 .vnc/passwd && \
touch .Xresources && \
touch .Xauthority && \
mkdir .user-dirs

ADD --chown=coder:coder --chmod=700 xstartup /home/coder/.vnc/xstartup
ADD --chown=coder:coder user-dirs.dirs /home/coder/.config/user-dirs.dirs
RUN chmod +x /home/coder/.vnc/xstartup

# Extensions gallery for code-server (Microsoft instead of OpenVSIX -> for when you use coder/code-server)
ENV EXTENSIONS_GALLERY='{"serviceUrl":"https://marketplace.visualstudio.com/_apis/public/gallery","cacheUrl":"https://vscode.blob.core.windows.net/gallery/index","itemUrl":"https://marketplace.visualstudio.com/items","controlUrl":"","recommendationsUrl":""}'
ENV DEBIAN_FRONTEND="dialog"
ENV LANG="en_US.UTF-8"
