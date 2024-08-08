#!/bin/bash

echo "Updating package list..."
sudo apt update

echo "Installing packages needed..."

sudo apt install build-essential #no need to install this
#instead of this install gcc current version
#using command sudo apt install gcc-13

echo "Installing meson, ninja-build and pyelftools packages of python"
sudo apt install meson ninja-build
sudo apt install python3-pyelftools
sudo apt install libnuma-dev pkgconf
sudo apt install libisal-dev libpcap-dev libxdp-dev libssl-dev libbpf-dev
echo 

wget https://fast.dpdk.org/rel/dpdk-${dpdk_version}.tar.xz
echo "Extracting software package..."
tar xJf dpdk-${dpdk_version}.tar.xz

cd "dpdk-stable-${dpdk_version}"

echo "Installing DPDK software..."
#sudo apt update
#sudo apt install pkg-config-aarch64-linux-gnu
#sudo apt install pkg-config-arm-linux-gnueabihf

CC=gcc meson setup build Dc_args="-march=${cpu_arch} -${opt_flag}" -Dexamples=${examples_list} --default-library=static 
ninja -C build install
ldconfig
