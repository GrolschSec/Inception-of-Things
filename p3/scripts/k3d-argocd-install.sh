#!/bin/bash

GREEN='\033[0;32m'

NC='\033[0m'

REPO='https://github.com/GrolschSec/rlouvrie42-IoT.git'

APP_NAME="playground-app"

# Check if the script is runned as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Installing docker and kubectl
apt update && apt install -y docker.io kubernetes-client

# Installing ArgoCD Cli
wget -O /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

chmod +x /usr/local/bin/argocd

# Adding the User to docker group
usermod -aG docker $USER

newgrp docker

# Installing k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Creating a cluster
k3d cluster create

# Creating the namespaces
kubectl create namespace argocd
kubectl create namespace dev

# Installing argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

while true; do
  kubectl wait --namespace argocd \
    --for=condition=ready pod \
    --timeout=10s --all && break
  echo "Some pods in the 'argocd' namespace are not ready yet, retrying in 10 seconds..."
  sleep 10
done

# Port forward argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443 & disown

ADMIN_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e $GREEN"ArgoCD Credentials -> Username: admin - Password: $ADMIN_PASS"$NC

argocd login 127.0.0.1:8080 --username admin --password $ADMIN_PASS --insecure

argocd app create $APP_NAME \
  --repo $REPO \
  --path ./ \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --sync-policy automated
