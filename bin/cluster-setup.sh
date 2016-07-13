#!/bin/bash

# This script is used to fire up base images for clusters


# Gathering base information required for operation from passed in parameters

clusterName=$1
rootPass=$2
adminPass=$3
vmImgPath=$4
baseImgFileName=$5

paramCount=$#


# Validation of parameters that have been passed into the script
function parameterValidation() {
	if [ $paramCount -gt 5 ]
	then
		echo "Too many parameters have been supplied"
		return 1
	elif [ $paramCount -lt 5 ]
	then
		echo "Not enough parameters have been supplied"
		return 1
	elif [ ! -d "$vmImgPath" ]
	then
		echo "Path to the vm images is invalid"
		return 1
	fi
}

# Validation of parameters
parameterValidation

validInputs="$?"

echo $validInputs

# Runs the main application if parameter validation has passed
if [ $validInputs -eq 0 ]
then
	echo "Running application"
fi
