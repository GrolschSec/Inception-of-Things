#!/bin/bash

sudo apt-get update && sudo apt-get install -y curl

IP=$(ip a s | grep "eth1" | grep "inet" | sed 's/^ \+//' | cut -d " " -f 2 | cut -f 1 -d "/" | cut -f 4 -d ".")

if [ $IP == 110 ]
then
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-group k3s --write-kubeconfig-mode=644 --flannel-iface eth1" sh -
    sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/token
elif [ $IP == 111 ]
then
    while [ ! -e "/vagrant/token" ]
    do
        sleep 1
    done

    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-iface eth1" K3S_TOKEN=$(sudo cat /vagrant/token) K3S_URL=https://192.168.56.110:6443 sh -
    sudo rm /vagrant/token
fi
