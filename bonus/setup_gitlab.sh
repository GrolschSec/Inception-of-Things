#!/bin/bash

sudo apt install git
sudo kubectl create namespace gitlab
sudo snap install helm --classic

HOST_ENTRY="127.0.0.1 gitlab.k3d.gitlab.com"
HOSTS_FILE="/etc/hosts"

if grep -q "$HOST_ENTRY" "$HOSTS_FILE"; then
    echo "exist $HOSTS_FILE"
else
    echo "adding $HOSTS_FILE"
    echo "$HOST_ENTRY" | sudo tee -a "$HOSTS_FILE"
fi

sudo helm repo add gitlab https://charts.gitlab.io/
sudo helm repo update 
sudo helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
  --set global.hosts.domain=k3d.gitlab.com \
  --set global.hosts.externalIP=0.0.0.0 \
  --set global.hosts.https=false \
  --timeout 600s

sudo kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab

echo -n "${GREEN}GITLAB PASSWORD : "
  sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode
echo "${RESET}"

sudo kubectl port-forward svc/gitlab-webservice-default -n gitlab 80:8181 2>&1 >/dev/null &