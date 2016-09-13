#!/bin/bash

# This script will stop and undefine a virsh instance of our cluster specified and remove the workspace.

usage() {

  echo "Usage: $0 <cluster name> <cluster workspace dir>"
  exit 1

}

# Gathering clusterName and clusterWorkspace parameters
if [[ -z $clusterName ]] || [[ -z $clusterWorkspace ]]; then
  if [ $1 ]; then
    clusterName=$1
  elif [ ! $1 ]; then
    echo "Cluster name not supplied"
    usage
  fi
  if [ $2 ]; then
    if [ -d "$2" ]; then
      clusterWorkspace=$2
    elif [ ! -d "$2" ]; then
      echo "The path to the instance workspace is invalid: $2"
      exit 1
    fi
  elif [ ! $2 ]; then
    echo "Cluster workspace not supplied"
    usage
  fi
fi

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
	virsh undefine "symphony-director.$clusterName"
	virsh undefine "symphony-directory.$clusterName"
	virsh undefine "symphony-monitor.$clusterName"
	virsh undefine "symphony-repo.$clusterName"


	# Deleting workspace directory
	rm -rf $clusterWorkspace

fi
