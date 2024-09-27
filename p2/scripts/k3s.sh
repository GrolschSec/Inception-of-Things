#!/bin/bash

apt-get update \
    && apt-get install -y curl python3-pip  \
    && pip3 install --break-system-packages bcrypt kubernetes

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-group k3s --write-kubeconfig-mode=644 --flannel-iface eth1" sh -

python3 /scripts/sethash.py /irc/

mkdir -p /irc-conf/ && cp /irc/*.json /irc-conf/ 

umount /irc && rm -rf /irc
umount /scripts && rm -rf /scripts

# Apply the Ingress NGINX Controller manifest
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/cloud/deploy.yaml

echo "Waiting for Ingress NGINX Controller to be ready..."
while true; do
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=10s && break
    echo "Ingress NGINX Controller is not ready yet, retrying in 10 seconds..."
    sleep 10
done
echo "Ingress NGINX Controller is ready."

kubectl apply -f /k3s/
