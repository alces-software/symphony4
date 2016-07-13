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
#	elif [[  ]]
#	then
#		echo "A cluster by this name is currently being setup or already in use"
#		return 1
	fi
}

# Clones a repo from GitHub. | cloneRepo(repoName, localWorkspace)
function cloneRepo() {
	echo "git clone https://github.com/alces-software/$1.git $2"
	git clone https://github.com/alces-software/$1.git $2
}


# Clones all base repos required from GitHub | cloneBaseRepos(clusterName)
function cloneBaseRepos() {
	cloneRepo symphony-director "/$1/symphony-director"
	cloneRepo symphony-directory "/$1/symphony-directory"
	cloneRepo symphony-monitor "/$1/symphony-monitor"
	cloneRepo symphony-repo "/$1/symphony-repo"
}

# Validation of parameters
parameterValidation

validInputs="$?"

echo $validInputs

# Runs the main application if parameter validation has passed
if [ $validInputs -eq 0 ]
then
	echo "Running application"

	# Creating directory to store git repositories in
	mkdir "/$clusterName"

	# Cloning GIT repositories from GitHub
	cloneBaseRepos $clusterName

	# Creating destination directory for generated configuration ISO files
	mkdir "$vmImgPath/$clusterName"
fi
