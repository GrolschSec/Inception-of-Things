#!/bin/bash

apt-get update \
    && apt-get install -y curl python3-pip  \
    && pip3 install --break-system-packages bcrypt kubernetes

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-group k3s --flannel-iface eth1" sh -

python3 /scripts/sethash.py /irc/

mkdir -p /irc-conf/ && cp /irc/*.json /irc-conf/ 

umount /irc && rm -rf /irc

umount /scripts && rm -rf /scripts

kubectl apply -f /k3s/
