#!/bin/bash

# Define the DPDK installation directory
DPDK_DIR="/usr/local/share/dpdk"
DPDK_INCLUDE_DIR="/usr/local/include/dpdk"
DPDK_LIB_DIR="/usr/local/lib/dpdk"
DPDK_BIN_DIR="/usr/local/bin"

# Remove DPDK directories
if [ -d "$DPDK_DIR" ]; then
    sudo rm -rf "$DPDK_DIR"
fi

if [ -d "$DPDK_INCLUDE_DIR" ]; then
    sudo rm -rf "$DPDK_INCLUDE_DIR"
fi

if [ -d "$DPDK_LIB_DIR" ]; then
    sudo rm -rf "$DPDK_LIB_DIR"
fi

# Remove DPDK binaries
for bin in dpdk*; do
    if [ -f "$DPDK_BIN_DIR/$bin" ]; then
        sudo rm -f "$DPDK_BIN_DIR/$bin"
    fi
done

# Clean up environment variables in .bashrc
sed -i '/export DPDK_DIR/d' ~/.bashrc
sed -i '/export PATH=\$DPDK_DIR/d' ~/.bashrc

# Source .bashrc to apply changes
source ~/.bashrc

echo "DPDK has been removed from the system."
