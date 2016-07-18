#!/bin/bash

# This script will stop and undefine a virsh instance of our cluster specified and remove the workspace.


# Gathering clusterName and clusterWorkspace parameters
if [ -z $clusterName ]
then
	clusterName=$1
fi

if [ -z $clusterWorkspace ]
then
	clusterWorkspace=$2
fi


# Function to validate script parameters to ensure that some have been supplied and validate with a working directory
function validateInputs() {
	if [ -z "$clusterWorkspace" ]
	then
		echo "A cluster workspace directory has not been supplied"
		return 1
	elif [ ! -d "$clusterWorkspace" ]
	then
		echo "The path to the instance workspace is invalid: $clusterWorkspace"
		return 1
	elif [ -z $clusterName ]
	then
		echo "A cluster name has not been supplied"
		return 1
	fi

}


# Validation of parameters
validateInputs

validInputs="$?"


# Runs the main application if parameter validation has passed
if [ $validInputs -eq 0 ]
then

	# Stopping all running modules of our cluster
	virsh destroy "symphony-director.$clusterName"
	virsh destroy "symphony-directory.$clusterName"
	virsh destroy "symphony-monitor.$clusterName"
	virsh destroy "symphony-repo.$clusterName"

	# Removing all modules of our cluster in virsh
	virsh destroy "symphony-director.$clusterName"
	virsh destroy "symphony-directory.$clusterName"
	virsh destroy "symphony-monitor.$clusterName"
	virsh destroy "symphony-repo.$clusterName"


	# Deleting workspace directory
	rm -rf $clusterWorkspace

fi
