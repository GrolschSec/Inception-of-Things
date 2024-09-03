#!/bin/bash

#Clearing the terminal
clear

# Removing the cluster
k3d cluster delete --all 2> /dev/null

# Removing all containers data
docker system prune -af
