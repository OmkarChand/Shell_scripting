#!/bin/bash

sudo apt update

config_file="config.cfg"

#Script to compare required and installed versions
compare_versions() {
    local ver1="$1"  # required version (from config file)
    local ver2="$2"  # installed version

    if [[ "$ver1" == "$ver2" ]]; then
        echo "successful"
        return 0
    fi

    local IFS=.
    local ver1_parts=( $ver1 )
    local ver2_parts=( $ver2 )

    local length=$(( ${#ver1_parts[@]} >= ${#ver2_parts[@]} ? ${#ver1_parts[@]} : ${#ver2_parts[@]} ))

    for (( i=0; i<length; i++ )); do
        part1=${ver1_parts[i]:-0}  # default to 0 if part1 is unset
        part2=${ver2_parts[i]:-0}  # default to 0 if part2 is unset

        if (( part1 > part2 )); then
            echo "unsuccessful"
            return 1
        elif (( part1 < part2 )); then
            echo "successful"
            return 0
        fi
    done

    echo "successful"
    return 0
}

#Script to extract data from config file
read_config() {
        local config_file="$1"
        local section="$2"
        local key="$3"
        local value

        #Reading value form the config file using awk
        # -v to create awk variable and -F is to set feild seperator
        value=$(awk -F'=' -v section="$section" -v key="$key" '
        /^\[.*\]$/ { current_section=$1 }
        current_section == "[" section "]" && $1 == key {
            gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2
        }
    ' "$config_file")

        echo "$value"
}

#Reading valuse from config file
config_pktgen=$(read_config "config.cfg" "Versions" "pktgen")

echo "[Required PKTGEN version = $config_pktgen]"
echo

installed_pktgen=$(pktgen --version 2>/dev/null || echo "null")

compare_pktgen=$(compare_versions "$config_pktgen" "$installed_pktgen")
echo "$compare_pktgen"

if [[ $compare_pktgen == "successful" ]]; then
	echo "[Required PKTGEN version $config_pktgen or higher is already installed...]"
else
	echo "[PKTGEN version $installed_pktgen dosen't meet the requirement]"
	echo
	# Check if the dpdk file already exists
        if [ ! -f "pktgen-dpdk-pktgen-$config_pktgen.tar.xz" ]; then
                # file doesn't exist, download it
                echo "[Downloading pktgen-$config_pktgen]"
                echo
                wget "https://git.dpdk.org/apps/pktgen-dpdk/snapshot/pktgen-dpdk-pktgen-${config_pktgen}.tar.xz"
                echo
                echo "[Downloaded successfully]"
                echo
        else
                # file exists, print a message or perform other actions
                echo "[file pktgen-dpdk-pktgen-${dpdk_version}.tar.xz already exists. Skipping download.]"
        fi

        echo
        echo "[Extracting the downloaded file...]"
        echo
	tar xJf pktgen-dpdk-pktgen-${config_pktgen}.tar.xz
	cd pktgen-dpdk-pktgen-${config_pktgen}
	
	#file_path="/app/pktgen-port-cfg.c"

	# Use sed to replace the format specifier at line 251
	#sed -i '251s/%d/%ld/' "$file_path"
	curr_dir=$(pwd)
	#echo "$curr_dir"
	sed -i '251s/%d/%ld/' "${curr_dir}/app/pktgen-port-cfg.c"

	echo "[Installing the dependencies like 'gcc', 'make', 'lua', and, 'libbsd']"
	
	sudo apt install -y gcc cmake libbsd-dev
	#sudo apt install -y liblua5.3-dev
	#sudo apt install -y liblua5.4-dev
	sudo apt install -y build-essential liblua5.3-dev liblua5.4-dev

	echo "[Installing required PKTGEN version $config_pktgen ...]"

	CC=gcc make buildlua
	
	#if command -v pktgen >/dev/null 2>&1; then
    	#	# If installed, print the version
    	#	echo "pktgen version: $(pktgen --version)"
	#else
    	#	# If not installed, print an error message
    	#	echo "pktgen is not installed or not in your PATH."
	#fi	
fi
