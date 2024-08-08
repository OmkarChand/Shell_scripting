#!/bin/bash

#sudo apt update

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing Git..."
    
    # Install Git
    sudo apt install -y git
    
    # Verify the installation
    if command -v git &> /dev/null; then
        echo "Git has been successfully installed."
    else
        echo "There was an issue installing Git."
    fi
else
    echo "Git is already installed."
fi

# Define the directory where the repository will be cloned
REPO_DIR_PKTGEN="pktgen-dpdk"

# Check if the directory exists
if [ -d "$REPO_DIR_PKTGEN" ]; then
    echo "Directory '$REPO_DIR_PKTGEN' already exists. Skipping git clone."
else
    echo "Directory '$REPO_DIR_PKTGEN' does not exist. Cloning repository..."
    git clone git://dpdk.org/apps/pktgen-dpdk
fi

# Define the directory where the repository will be cloned
REPO_DIR_DPDK="dpdk"

# Check if the directory exists
if [ -d "$REPO_DIR_DPDK" ]; then
    echo "Directory '$REPO_DIR_DPDK' already exists. Skipping git clone."
else
    echo "Directory '$REPO_DIR_DPDK' does not exist. Cloning repository..."
    git clone git://dpdk.org/apps/pktgen-dpdk
fi

kernel_version=$(uname -r | awk '{print $1}')
#echo "Kernel version = $kernel_version"
#echo

#sudo apt-get install linux-headers-$kernel_version
#sudo apt-get install libpcap-dev

curr_dir=$(pwd)
#echo "Current directory = $curr_dir"
#echo

export RTE_SDK=$curr_dir/dpdk
#echo "RTE_SDK = $RTE_SDK"
#echo
export RTE_TARGET=x86_64-native-linux-gcc

cd $RTE_SDK
make install T=x86_64-native-linux-gcc

cd $curr_dir/pktgen-dpdk
make

cd $curr_dir/pktgen-dpdk/tools
./run.py -s default  # setup system using the cfg/default.cfg file

