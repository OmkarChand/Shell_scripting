#!/bin/bash

#function to read the config file
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

config_file="config.cfg"

#Reading valuse from config file
python_version=$(read_config "$config_file" "Versions" "python")

#echo "python version in config file is $python_version"

check_py=$(python3.9 --version | awk '{print $2}')

#echo "installed  version is $check_py"

compare_versions(){
	local ver1="$1"
	local ver2="$2"

	if [[ "$ver1" == "$ver2" ]]; then
		echo "success"
		return 0
	fi

	local IFS=.
	local ver1_parts=($ver1)
	local ver2_parts=($ver2)

	local length=$(( ${#ver1_parts[@]} >= ${#ver2_parts[@]} ? ${#ver1_parts[@]} : ${#ver2_parts[@]} ))
	
	for ((i=0; i<length; i++)); do
		part1=${ver1_parts[i]-0}
		parts=${ver2_parts[i]-0}

		if (( part1 > part2 )); then
			echo "not success"
			return 0
		elif (( part1 < part2 )); then
			echo "not success"
			return 1
		fi
	done
	echo "success"
	return 0
}

result=$(compare_versions "$check_py" "$python_version")

echo "$result"

if [[ $result == "success" ]]; then
	echo "$python python_version is already installed"
	exit 0
else 
	python_package="python$python_version"
	echo "Installing python $python_version"
	sudo apt-get update
	sudo apt-get install -y "$python_package"
fi

installed_version=$(python3 --version 2>$1)
echo
echo "installed version = $installed_version"
echo
echo "python installed"
