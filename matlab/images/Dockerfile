# Copyright 2019 - 2022 The MathWorks, Inc.

# To specify which MATLAB release to install in the container, edit the value of the MATLAB_RELEASE argument.
# Use lower case to specify the release, for example: ARG MATLAB_RELEASE=r2021b
ARG MATLAB_RELEASE=r2022a

# When you start the build stage, this Dockerfile by default uses the Ubuntu-based matlab-deps image.
# To check the available matlab-deps images, see: https://hub.docker.com/r/mathworks/matlab-deps
FROM mathworks/matlab:latest

# # Declare the global argument to use at the current build stage
ARG MATLAB_RELEASE

# # Set user as root
USER root

# Install mpm dependencies
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && \
    apt-get install --no-install-recommends --yes \
        wget \
        unzip \
        ca-certificates && \
    apt-get clean && apt-get autoremove

# Run mpm to install MATLAB in the target location and delete the mpm installation afterwards.
# If mpm fails to install successfully then output the logfile to the terminal, otherwise cleanup.
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \ 
    chmod +x mpm && \
    ./mpm install \
        --release=${MATLAB_RELEASE} \
        --destination=/opt/matlab \
        --products MATLAB \
                   Signal_Processing_Toolbox \
                   DSP_System_Toolbox \
                   Image_Processing_Toolbox \
                   Computer_Vision_Toolbox \
                   Control_System_Toolbox \
                   System_Identification_Toolbox \
                   Communications_Toolbox \
                   5G_Toolbox \
                   LTE_Toolbox \
                   WLAN_Toolbox \
                   Bluetooth_Toolbox \
                   Satellite_Communications_Toolbox \
                   Wireless_Testbench || \
    (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false)
RUN rm -f mpm /tmp/mathworks_root.log
# Not needed because we are alreday using a base matlab image
# RUN ln -s /opt/matlab/bin/matlab /usr/local/bin/matlab 

USER matlab
