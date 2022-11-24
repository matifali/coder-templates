FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# Set the locale and timezone
ENV TZ=Europe/Istanbul LANG=en_US.UTF-8 LANGUAGE=en_US:en

####################
# Add Xubuntu Mate Desktop
####################
RUN apt-get update -q && apt-get upgrade -y && apt-get install -y \
    ubuntu-mate-desktop && rm -rf /var/lib/apt/lists/*

####################
# Add Package
####################
RUN apt-get update && apt-get install -y \
    tigervnc-standalone-server tigervnc-common \
    supervisor novnc websockify gosu && apt-get autoclean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

####################
# Add User
####################
ENV USERNAME=coder
ENV USER=${USERNAME}
RUN useradd --home-dir /home/$USERNAME --shell /bin/bash --create-home --user-group --groups adm,sudo --uid 1000 $USERNAME
RUN echo $USER:$USER | /usr/sbin/chpasswd
RUN mkdir -p /home/$USER/.vnc && echo $USER | vncpasswd -f >/home/$USER/.vnc/passwd && chmod 600 /home/$USER/.vnc/passwd && chown -R $USER:$USER /home/$USER

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
USER $USERNAME
CMD ["/usr/bin/supervisord"]
