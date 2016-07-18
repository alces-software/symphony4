#!/bin/bash

# This script is used to fire up base images for clusters


# Reading script configuration from a config file if there is one available.
if [ -f ./cluster-config ]
then

	# Reading paramaters from config file
	IFS=', ' read -r -a params <<< $( cat cluster-config)
	
	# Setting parameters from items read in config file
	clusterName=${params[0]}
	rootPass=${params[1]}
	adminPass=${params[2]}
	vmImgPath=${params[3]}
	baseImgFileName=${params[4]}

fi


# Setting base information required for operation from passed in parameters if not previously set

if [ -z $clusterName  ]
then
	clusterName=$1
fi

if [ -z $rootPass ]
then
	rootPass=$2
fi

if [ -z $adminPass ]
then
	adminPass=$3
fi

if [ -z $vmImgPath ]
then
	vmImgPath=$4
fi

if [ -z $baseImgFileName ]
then
	baseImgFileName=$5
fi


# Validation of parameters that have been passed into the script
function parameterValidation() {
	if [ ! -d "$vmImgPath" ]
	then
		echo "Path to the vm images is invalid"
		return 1
	elif [ -d "$vmImgPath/$clusterName" ]
	then
		echo "The directory \"$vmImgPath/$clusterName\" already exists and may currently be in use"
		return 1
	elif [ -d "/tmp/$clusterName" ]
	then
		echo "The directory \"/tmp/$clusterName\" already exists and may currently be in use"
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
	cloneRepo symphony-director "/tmp/$1/symphony-director"
	cloneRepo symphony-directory "/tmp/$1/symphony-directory"
	cloneRepo symphony-monitor "/tmp/$1/symphony-monitor"
	cloneRepo symphony-repo "/tmp/$1/symphony-repo"
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
	sed -e "s/%CLUSTER%/$clusterName/g" -e "s/%ADMINPASSWORD%/$adminPass/g" -e "s/%ROOTPASSWORD%/$rootPass/g" "/tmp/$clusterName/symphony-$moduleName/install/configdrive/meta-data" > "$vmImgPath/$clusterName/meta-data"


	# Generating User Data config file
	sed -e "s/%CLUSTER%/$clusterName/g" -e "s/%ADMINPASSWORD%/$adminPass/g" -e "s/%ROOTPASSWORD%/$rootPass/g" "/tmp/$clusterName/symphony-$moduleName/install/configdrive/user-data" > "$vmImgPath/$clusterName/user-data"

	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo "-- Generating XML --"
	echo

	# Generating symphony XML to define the instance
	sed -e "s|%CLUSTER%|$clusterName|g" -e "s|%CLUSTERNAME%|$clusterName|g" -e "s|%IMGPATH%|$vmImgPath/$clusterName|g" "/tmp/$clusterName/symphony-$moduleName/install/libvirt/symphony-$moduleName.xml" > "$vmImgPath/$clusterName/symphony-$moduleName.xml"


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
	cp -v "$baseImgFileName" "$vmImgPath/$clusterName/centos7-symphony-$moduleName.qcow2"



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
	mkdir "/tmp/$clusterName"


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
