# Copyright 2019 - 2022 The MathWorks, Inc.

# When you start the build stage, this Dockerfile by default uses the Ubuntu-based matlab-deps image.
# To check the available matlab-deps images, see: https://hub.docker.com/r/mathworks/matlab-deps
FROM mathworks/matlab:r2022b

# Set user as root
USER root

# Install mpm dependencies
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && \
    apt-get install --no-install-recommends --yes \
    wget \
    unzip \
    ca-certificates && \
    apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*
 
    # Run mpm to install MATLAB in the target location and delete the mpm installation afterwards.
    # If mpm fails to install successfully then output the logfile to the terminal, otherwise cleanup.
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && chmod +x mpm && \
    ./mpm install \
    --release=R2022b \
    --destination=/opt/matlab/R2022b/ \
    --products 5G_Toolbox \
    #AUTOSAR_Blockset \
    #Aerospace_Blockset \
    Aerospace_Toolbox \
    Antenna_Toolbox \
    Audio_Toolbox \
    Automated_Driving_Toolbox \
    Bioinformatics_Toolbox \
    Bluetooth_Toolbox \
    Communications_Toolbox \
    Computer_Vision_Toolbox \
    Control_System_Toolbox \
    Curve_Fitting_Toolbox \
    #DDS_Blockset \
    #DO_Qualification_Kit \
    DSP_HDL_Toolbox \
    DSP_System_Toolbox \
    #Database_Toolbox \
    #Datafeed_Toolbox \
    #Deep_Learning_HDL_Toolbox \
    Deep_Learning_Toolbox \
    #Econometrics_Toolbox \
    #Embedded_Coder \
    #Filter_Design_HDL_Coder \
    #Financial_Instruments_Toolbox \
    #Financial_Toolbox \
    Fixed-Point_Designer \
    Fuzzy_Logic_Toolbox \
    #GPU_Coder \
    Global_Optimization_Toolbox \
    #HDL_Coder \
    #HDL_Verifier \
    #IEC_Certification_Kit \
    #Image_Acquisition_Toolbox \
    Image_Processing_Toolbox \
    #Industrial_Communication_Toolbox \
    #Instrument_Control_Toolbox \
    LTE_Toolbox \
    Lidar_Toolbox \
    MATLAB \
    MATLAB_Coder \
    MATLAB_Compiler \
    MATLAB_Compiler_SDK \
    MATLAB_Parallel_Server \
    #MATLAB_Production_Server \
    MATLAB_Report_Generator \
    #MATLAB_Web_App_Server \
    Mapping_Toolbox \
    # Mixed-Signal_Blockset \
    Model_Predictive_Control_Toolbox \
    # Motor_Control_Blockset \
    Navigation_Toolbox \
    Optimization_Toolbox \
    Parallel_Computing_Toolbox \
    Partial_Differential_Equation_Toolbox \
    Phased_Array_System_Toolbox \
    #Polyspace_Bug_Finder \
    #Polyspace_Bug_Finder_Server \
    #Polyspace_Code_Prover \
    #Polyspace_Code_Prover_Server \
    #Powertrain_Blockset \
    #Predictive_Maintenance_Toolbox \
    # RF_Blockset \
    RF_PCB_Toolbox \
    RF_Toolbox \
    ROS_Toolbox \
    Radar_Toolbox \
    Reinforcement_Learning_Toolbox \
    #Requirements_Toolbox \
    #Risk_Management_Toolbox \
    Robotics_System_Toolbox \
    Robust_Control_Toolbox \
    Satellite_Communications_Toolbox \
    Sensor_Fusion_and_Tracking_Toolbox \
    #SerDes_Toolbox \
    Signal_Integrity_Toolbox \
    Signal_Processing_Toolbox \
    #SimBiology \
    #SimEvents \
    #Simscape \
    #Simscape_Driveline \
    #Simscape_Electrical \
    #Simscape_Fluids \
    #Simscape_Multibody \
    #Simulink \
    #Simulink_3D_Animation \
    #Simulink_Check \
    #Simulink_Code_Inspector \
    #Simulink_Coder \
    #Simulink_Compiler \
    #Simulink_Control_Design \
    #Simulink_Coverage \
    #Simulink_Design_Optimization \
    #Simulink_Design_Verifier \
    #Simulink_Desktop_Real-Time \
    #Simulink_PLC_Coder \
    #Simulink_Real-Time \
    #Simulink_Report_Generator \
    #Simulink_Test \
    #SoC_Blockset \
    #Spreadsheet_Link \
    #Stateflow \
    Statistics_and_Machine_Learning_Toolbox \
    Symbolic_Math_Toolbox \
    #System_Composer \
    System_Identification_Toolbox \
    Text_Analytics_Toolbox \
    UAV_Toolbox \
    # Vehicle_Dynamics_Blockset \
    Vehicle_Network_Toolbox \
    #Vision_HDL_Toolbox \
    WLAN_Toolbox \
    Wavelet_Toolbox \
    #Wireless_HDL_Toolbox \
    Wireless_Testbench || \
    (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false) && \
    rm -f mpm /tmp/mathworks_root.log && \
    rm /usr/local/bin/matlab && \
    ln -s /opt/matlab/bin/matlab /usr/local/bin/matlab

WORKDIR /
# Seems to be needed for -browser version to install addons
RUN mkdir /.Add-Ons && \
    chown -R matlab /.Add-Ons

USER matlab
WORKDIR /home/matlab/data
