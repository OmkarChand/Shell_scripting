#!/bin/bash

echo "updating package list..."
#sudo apt update
echo

echo "Installing additional packages..."
#sudo apt install build-essential

KERNEL=$(uname -r | awk -F'-' '{ print $1 }')
GLIBC=$(ldd --version | head -n 1 | awk '{ print $NF }')
GCC_VERSION=$(gcc --version | awk '/gcc/ { print $NF }')
CURRENT_PY=$(python3 -V | awk '{ print $2 }')
CURRENT_MESON=$(meson --version | awk '{print $1}')
CURRENT_NINJA=$(ninja --version | awk '{print $1}')
CURRENT_PYELFTOOLS=$(pip show pyelftools | awk '/Version:/ { print $2 }')

echo "KERNEL=$KERNEL"
echo
echo "GLIBC=$GLIBC"
echo
echo "GCC=$GCC_VERSION"
echo
echo "PYTHON=$CURRENT_PY"
echo
echo "MESON=$CURRENT_MESON"
echo
echo "NINJA=$CURRENT_NINJA"
echo
echo "PYELFTOOLS=$CURRENT_PYELFTOOLS"
echo 

MIN_KERNEL="4.14"
MIN_GLIBC="2.7"

compare_versions(){
    local ver1="$1"
    local ver2="$2"

    if [[ "$ver1" == "$ver2" ]]; then
        echo "Versions are equal"
        return 0
    fi

    # setting internal field separator (IFS)
    local IFS=.
    local ver1_parts=($ver1)
    local ver2_parts=($ver2)
    
    # finding the max length from arrays ver1_parts and ver2_parts
    local length=$(( ${#ver1_parts[@]} > ${#ver2_parts[@]} ? ${#ver1_parts[@]} : ${#ver2_parts[@]} ))
    
    # compare each part of the version numbers
    for ((i=0; i<length; i++)); do
        local part1=${ver1_parts[i]-0}  # Use default value of 0 if unset
        local part2=${ver2_parts[i]-0}  # Use default value of 0 if unset

        if (( part1 > part2 )); then
            echo "$ver1 is greater than $ver2"
            return 0
        elif (( part1 < part2 )); then
            echo "$ver1 is less than $ver2"
            return 1
        fi
    done
    
    echo "Versions $ver1 and $ver2 are equal"
    return 0
}

compare_versions "$KERNEL" "$MIN_KERNEL"
