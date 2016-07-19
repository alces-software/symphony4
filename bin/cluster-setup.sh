#!/bin/bash

# This script is used to fire up base images for clusters


# Reading script configuration from a config file if there is one available.
if [ -f ./cluster-config ]
then
#
#	# Reading paramaters from config file
#	IFS=', ' read -r -a params <<< $( cat cluster-config)
#	
#	# Setting parameters from items read in config file
#	clusterName=${params[0]}
#	rootPass=${params[1]}
#	adminPass=${params[2]}
#	vmImgPath=${params[3]}
#	baseImgFileName=${params[4]}
#

	source ./cluster-config

fi


# Setting base information required for operation from passed in parameters if not previously set




# Validation of parameters that have been passed into the script
function parameterValidation() {

	if [ -z $clusterName  ]
	then
		echo "Cluster name has not been set" >&2
		exit 2

	elif [ -z $rootPass ]
	then
		echo "Root password has not been set" >&2
		exit 2

	elif [ -z $adminPass ]
	then
		echo "Admin password has not been set" >&2
		exit 2

	elif [ -z $vmImgPath ]
	then
		echo "VM image path has not been set" >&2
		exit 2

	elif [ -z $baseImgFileName ]
	then
		echo "Base image file name has not been set" >&2
		exit 2

	elif [ ! -d "$vmImgPath" ]
	then
		echo "Path to the vm images is invalid" >&2
		exit 2
	elif [ -d "$vmImgPath/$clusterName" ]
	then
		echo "The directory \"$vmImgPath/$clusterName\" already exists and may currently be in use" >&2
		exit 2
	elif [ -d "/tmp/$clusterName" ]
	then
		echo "The directory \"/tmp/$clusterName\" already exists and may currently be in use" >&2
		exit 2
	elif [ -z $buildNetworkType ]
	then
		echo "Build network type has not been set"
		exit 2
	elif [ -z $buildNetworkName ]
	then
		echo "Build network name has not been set"
		exit 2
	elif [ $buildNetworkType != "bridge" ] && [ $buildNetworkType != "network" ]
	then
		echo "Build network type is incorrect. Network type can only be set to either \"bridge\" or \"network\""
		exit 2
	elif [ -z $privateNetworkType ]
	then
		echo "Private network type has not been set"
		exit 2
	elif [ -z $privateNetworkName ]
	then
		echo "Private network name has not been set"
		exit 2
	elif [ $privateNetworkType != "bridge" ] && [ $privateNetworkType != "network" ]
	then
		echo "Private network type is incorrect. Network type can only be set to either \"bridge\" or \"network\""
		exit 2
	elif [ -z $managementNetworkType ]
	then
		echo "Management network type has not been set"
		exit 2
	elif [ -z $managementNetworkName ]
	then
		echo "Management network name has not been set"
		exit 2
	elif [ $managementNetworkType != "bridge" ] && [ $managementNetworkType != "network" ]
	then
		echo "Management network type is incorrect. Network type can only be set to either \"bridge\" or \"network\""
		exit 2
	elif [ -z $dmzNetworkType ]
	then
		echo "DMZ network type has not been set"
		exit 2
	elif [ -z $dmzNetworkName ]
	then
		echo "DMZ network name has not been set"
		exit 2
	elif [ $dmzNetworkType != "bridge" ] && [ $dmzNetworkType != "network" ]
	then
		echo "DMZ network type is incorrect. Network type can only be set to either \"bridge\" or \"network\""
		exit 2
	elif [ -z $externalNetworkType ]
	then
		echo "External network type has not been set"
		exit 2
	elif [ -z $externalNetworkName ]
	then
		echo "External network name has not been set"
		exit 2
	elif [ $externalNetworkType != "bridge" ] && [ $externalNetworkType != "network" ]
	then
		echo "External network type is incorrect. Network type can only be set to either \"bridge\" or \"network\""
		exit 2
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
	sed -e "s|%CLUSTER%|$clusterName|g" -e "s|%CLUSTERNAME%|$clusterName|g" -e "s|%IMGPATH%|$vmImgPath/$clusterName|g" -e "s|%BUILDNETWORKTYPE%|$buildNetworkType|g" -e "s|%BUILDNETWORKNAME%|$buildNetworkName|g" -e "s|%PRIVATENETWORKTYPE%|$privateNetworkType|g" -e "s|%PRIVATENETWORKNAME%|$privateNetworkName|g" -e "s|%MANAGEMENTNETWORKTYPE%|$managementNetworkType|g" -e "s|%MANAGEMENTNETWORKNAME%|$managementNetworkName|g" -e "s|%DMZNETWORKTYPE%|$dmzNetworkType|g" -e "s|%DMZNETWORKNAME%|$dmzNetworkName|g" -e "s|%EXTERNALNETWORKTYPE%|$externalNetworkType|g" -e "s|%EXTERNALNETWORKNAME%|$externalNetworkName|g" "/tmp/$clusterName/symphony-$moduleName/install/libvirt/symphony-$moduleName.xml" > "$vmImgPath/$clusterName/symphony-$moduleName.xml"


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
	if ! `virsh define "$vmImgPath/$clusterName/symphony-$moduleName.xml"`
	then
		echo "Failed to define $vmImgPath/$clusterName/symphony-$moduleName.xml" >&2
		exit 1
	fi

	echo
	echo
	echo "------------------------------------------------------------------"
	echo "------------------------------------------------------------------"
	echo
	echo
	echo "-- Starting Cluster Instance --"
	echo

	# Starting cluster instance
	if ! `virsh start "symphony-$moduleName.$clusterName"`
	then
		echo "Failed to start symphony-$moduleName.$clusterName" >&2
		exit 1
	fi

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


	# Removing staging area
	rm -rf /tmp/$clusterName
fi
