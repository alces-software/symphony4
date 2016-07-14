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
	elif [ -d "$vmImgPath/$clusterName" ]
	then
		echo "The directory \"$vmImgPath/$clusterName\" already exists and may currently be in use"
		return 1
	elif [ -d "/$clusterName" ]
	then
		echo "The directory \"/$clusterName\" already exists and may currently be in use"
		return 1
	fi
}

# Clones a repo from GitHub. | cloneRepo(repoName, localWorkspace)
function cloneRepo() {
	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo
	echo "git clone https://github.com/alces-software/$1.git $2"
	echo
	echo
	git clone https://github.com/alces-software/$1.git $2
}


# Clones all base repos required from GitHub | cloneBaseRepos(clusterName)
function cloneBaseRepos() {
	cloneRepo symphony-director "/$1/symphony-director"
	cloneRepo symphony-directory "/$1/symphony-directory"
	cloneRepo symphony-monitor "/$1/symphony-monitor"
	cloneRepo symphony-repo "/$1/symphony-repo"
}


# Building, defining, and starting a module as part of the cluster instance
# buildModule(moduleName)
function buildModule() {
	moduleName=$1



	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo
	echo "-- Generating User & Meta Data Configs --"
	echo

	# Generating Meta Data config file
	sed -e "s/%CLUSTER%/$clusterName/g" -e "s/%ADMINPASSWORD%/$adminPass/g" -e "s/%ROOTPASSWORD%/$rootPass/g" "/$clusterName/symphony-$moduleName/install/configdrive/meta-data" > "$vmImgPath/$clusterName/meta-data"


	# Generating User Data config file
	sed -e "s/%CLUSTER%/$clusterName/g" -e "s/%ADMINPASSWORD%/$adminPass/g" -e "s/%ROOTPASSWORD%/$rootPass/g" "/$clusterName/symphony-$moduleName/install/configdrive/user-data" > "$vmImgPath/$clusterName/user-data"

	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo "-- Generating XML --"
	echo

	# Generating symphony XML to define the instance
	sed -e "s|%CLUSTER%|$clusterName|g" -e "s|%CLUSTERNAME%|$clusterName|g" -e "s|%IMGPATH%|$vmImgPath/$clusterName|g" "/$clusterName/symphony-$moduleName/install/libvirt/symphony-$moduleName.xml" > "$vmImgPath/$clusterName/symphony-$moduleName.xml"


	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo
	echo "-- Generating ISO --"
	echo


	# Generating ISO
	genisoimage -o "$vmImgPath/$clusterName/symphony-$moduleName-config.iso" -V cidata -r -J "$vmImgPath/$clusterName/meta-data" "$vmImgPath/$clusterName/user-data"

	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo
	echo "-- Copying Base Image --"
	echo

	# Copying base vm image to workspace
	cp -v "$vmImgPath/imagebuilder-release/centos7-symphony-4.qcow2" "$vmImgPath/$clusterName/centos7-symphony-$moduleName.qcow2"



	# Checks the current module is the repo module as it requires additional resources
	if [ $moduleName == "repo" ]
	then
		# Creating additional repo datadisks
		qemu-img create -f qcow2 -o preallocation=metadata "$vmImgPath/$clusterName/symphony-repo-pulp.qcow2" 80G
		qemu-img create -f qcow2 -o preallocation=metadata "$vmImgPath/$clusterName/symphony-repo-mongo.qcow2" 80G
	fi



	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo
	echo "-- Defining Cluster Instance --"
	echo

	# Defining the cluster domain in virsh
	virsh define "$vmImgPath/$clusterName/symphony-$moduleName.xml"


	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo
	echo "-- Starting Cluster Instance --"
	echo

	# Starting cluster instance
	virsh start "symphony-$moduleName.$clusterName"

	echo
	echo
	echo "Module started: $moduleName"
	echo
	echo
}




# Validation of parameters
parameterValidation

validInputs="$?"

echo $validInputs

# Runs the main application if parameter validation has passed
if [ $validInputs -eq 0 ]
then
	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo
	echo "Running application"


	# Creating directory to store git repositories in
	mkdir "/$clusterName"


	# Cloning GIT repositories from GitHub
	cloneBaseRepos $clusterName


	# Creating destination directory for generated configuration ISO files
	mkdir "$vmImgPath/$clusterName"


	# Building modules for cluster instance
	buildModule director
	buildModule directory
	buildModule monitor
	buildModule repo


	# Removing User and Meta data files that are no longer required
	rm -f "$vmImgPath/$clusterName/meta-data"
	rm -f "$vmImgPath/$clusterName/user-data"
fi
