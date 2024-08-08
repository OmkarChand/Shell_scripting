#!/bin/bash

echo "[Updating packages...]"
echo
sudo apt update
echo

curr_dir=$(pwd)
config_file="$curr_dir/config.cfg"

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
            echo "unsuccessful"
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
config_gcc=$(read_config "config.cfg" "Versions" "compiler")

echo "[Required GCC version is $config_gcc]"
echo

installed_gcc=$(gcc --version | awk '/gcc/ { print $NF }')
echo "[Installed GCC version is $installed_gcc]"
echo

check=$(compare_versions "$config_gcc" "$installed_gcc")
#echo "$check"

if [[ $check == "successful" ]]; then
	echo "[Required GCC version $config_gcc or higher is already installed...]"
else
	echo "[GCC version $installed_gcc dosen't meet the requirement]"
	version_to_install="${config_gcc%%.*}"
	echo
	echo "[Installing required GCC version $version_to_install ...]"
	echo
	if sudo apt install -y gcc-"$version_to_install"; then
		echo
		echo "[Successfully installed GCC version $version_to_install]"
	else
		echo
		echo "[Failed to install GCC version $version_to_install]"
		exit 0
	fi
fi

echo
echo "[Installing meson, ninja-build and pyelftools packages...]"
echo

sudo apt install meson ninja-build
sudo apt install python3-pyelftools
sudo apt install libnuma-dev pkgconf
sudo apt install libisal-dev libpcap-dev libxdp-dev libssl-dev libbpf-dev
echo

#echo "Downloading the DPDk tool..."

dpdk_version=$(read_config "config.cfg" "Versions" "dpdk")

echo
echo "[DPDK version in config file is dpdk-$dpdk_version]"
echo

examples_list=$(read_config "config.cfg" "Carch" "examples_list")
#echo "[Examples list = $examples_list]"
#echo

#--------------start
# Function to parse a key from config file into array

parse_config_key() {
    local section="$1"
    local key="$2"
    local delimiter="$3"
    
    # Read value from config file based on section and key
    local value=$(awk -F'=' -v section="$section" -v key="$key" '$1 == "["section"]" && $1 != "" {f=1} f&&$1==key {sub(/^[^=]*=/, ""); print $1; f=0}' "$config_file")

    # Check if value is not empty
    if [ -n "$value" ]; then
        # Split value into array using delimiter
        IFS="$delimiter" read -ra array_value <<< "$value"

        # Trim leading and trailing whitespace from each array element
        array_value=("${array_value[@]// /}")
        echo "${array_value[@]}"
    fi
}

# Function to prompt user to select an option from an array
# Arguments: array_name (passed as "$@")
prompt_user_select() {
    local array=("$@")

    #echo "Available options for $key:"
    for ((i=0; i<${#array[@]}; i++)); do
        echo "$(($i + 1)). ${array[$i]}"
    done
    echo

    # Prompt user for selection
    read -rp "Select one option [1-${#array[@]}]: " selection

    # Validate user input
    re='^[0-9]+$'
    if ! [[ $selection =~ $re ]] || (( selection < 1 || selection > ${#array[@]} )); then
        echo "Error: Invalid selection. Please enter a number between 1 and ${#array[@]}."
        prompt_user_select "${array[@]}"
    else
        selected_option=${array[$(($selection - 1))]}
        #echo "Selected option = $selected_option"
        # Further logic with selected_option
    fi
}
#-------------------

installed_dpdk=$(pkg-config --modversion libdpdk | awk '{print $1}')
compare_dpdk=$(compare_versions "$dpdk_version" "$installed_dpdk")
#echo "$compare_dpdk"
#echo
if [[ $compare_dpdk == "successful" ]]; then
        echo "Required DPDK version $dpdk_version is already installed..."
	check_gcc_dpdk=$(readelf -p .comment /usr/local/bin/dpdk-testpmd | awk '/GCC/ { print $NF }')
        echo "[GCC version: $check_gcc_dpdk]"
	new_dpdk=$(pkg-config --modversion libdpdk | awk '{print $1}')
        echo "[DPDK version: $new_dpdk]"
        echo

else
        echo "[DPDK version $installed_dpdk dosen't meet the requirement]"
        echo
	# Check if the dpdk file already exists
	if [ ! -f "dpdk-$dpdk_version.tar.xz" ]; then
    		# File doesn't exist, download it
    		echo "Downloading dpdk-$dpdk_version..."
    		echo
    		wget "https://fast.dpdk.org/rel/dpdk-$dpdk_version.tar.xz"
    		echo
    		echo "Downloaded successfully"
    		echo
	else
    		# File exists, print a message or perform other actions
    		echo "File dpdk-$dpdk_version.tar.xz already exists. Skipping download."
	fi

	echo
	echo "Extracting the downloaded file..."
	echo
	tar xJf dpdk-$dpdk_version.tar.xz
	echo
	stable=$(echo "$dpdk_version" | awk -F"." '{print $2}')
	if [ $stable == 11 ]; then
		echo "stable"
		cd "dpdk-stable-$dpdk_version"
		echo
		#pwd
	else
		echo "normal"
		cd "dpdk-$dpdk_version"
		echo
		#pwd
	fi
        echo "Installing required DPDK version $dpdk_version ..."
        echo
        echo "need some information..."
        echo
	#------------------------
	# Main script execution starts here
	#echo "Reading opt_flag from Carch section..."
	result_opt_flags=($(parse_config_key "Carch" "opt_flag" "|"))
	if [ -n "${result_opt_flags}" ]; then
		#echo "opt_flag found in [Carch]: ${result_opt_flags[@]}"
        	#echo
		#key="opt_flags"
		echo "Available options for optimisation flags:"
        	prompt_user_select "${result_opt_flags[@]}"
		selected_opt_flag="$selected_option"
		echo "selected option = $selected_opt_flag"
        	echo
	else
		echo "No opt_flag found in [Carch] section."
        	echo
	fi

	result_march=($(parse_config_key "Carch" "march" "|"))
	if [ -n "${result_march}" ]; then
        	#echo "march found in [Carch]: ${result_march[@]}"
        	#echo
        	#key="opt_flags"
        	echo "Available options for march:"
        	prompt_user_select "${result_march[@]}"
		selected_march="$selected_option"
        	echo "selected option = $selected_march"
        	echo
	else
        	echo "No march option found in [Carch] section."
        	echo
	fi
	#-----------------------
        # Create the build directory if it does not exist
	mkdir -p build

	# Run the meson setup with the proper environment variables
	CC=gcc meson setup build -Dc_args="-march=${selected_march} -${selected_opt_flag}" -Dexamples=${examples_list} --default-library=static

	# Run ninja to build the project
	ninja -C build

	# Run ninja install and ldconfig with sudo
	sudo ninja -C build install
	sudo ldconfig

	new_dpdk=$(pkg-config --modversion libdpdk | awk '{print $1}')
	new_compare_dpdk=$(compare_versions "$new_dpdk" "$dpdk_version")
        if [[ $new_compare_dpdk == "successful" ]]; then
        	echo
        	echo "dpdk-$dpdk_version installed succesfully"
		check_gcc_dpdk=$(readelf -p .comment /usr/local/bin/dpdk-testpmd | awk '/GCC/ { print $NF }')
		echo "[GCC version: $check_gcc_dpdk]"
		echo "[DPDK version: $new_dpdk]"
		echo
		#readelf -p .comment /usr/local/bin/dpdk-testpmd
S	else
                echo
                echo "Failed to install dpdk-$dpdk_version"
                exit 0
        fi
fi

#mkdir -p build
#sudo CC=gcc meson setup build Dc_args="-march=${selected_march} -${selected_opt_flag}" -Dexamples=${examples_list} --default-library=static
#sudo ninja -C build install
#sudo ldconfig
