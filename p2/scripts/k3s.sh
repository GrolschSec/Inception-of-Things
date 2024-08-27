#!/bin/bash

if [ ! -n $PBEHEYT_PASS ]
then
    echo "PBEHEYT_PASS IS NOT SET !"
    exit 1
elif [ ! -n $RLOUVRIE_PASS ]
then
    echo "RLOUVRIE_PASS IS NOT SET !"
    exit 1
fi

echo $PBEHEYT_PASS
echo $RLOUVRIE_PASS

# sudo apt-get update \
#     && sudo apt-get install -y curl python3-pip python3.11-venv \
#     && pip3 install bcrypt

# curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-group k3s --flannel-iface eth1" sh -

# kubectl apply -f /vagrant/
