#!/bin/bash

ARGOCD_INS=$(command -v argocd)

K3D_INS=$(command -v k3d)

HELM_INS=$(command -v helm)

APP_NAME="playground-app"

# Change that parameter to your local ip address
# MACHINE_IP="10.0.2.15"

echo_color() {
  NC='\033[0m'

  echo -e "$1$2$NC"
}

warning() {
  YELLOW=$(tput setaf 3)

  echo_color "$YELLOW" "[Warning] - $1"
}

success() {
  GREEN=$(tput setaf 2)
  BOLD=$(tput bold)

  echo_color "$BOLD$GREEN" "[Success] - $1"
}

error() {
  RED=$(tput setaf 1)
  BOLD=$(tput bold)

  echo_color "$BOLD$RED" "[Error] - $1"
}

info() {
  BLUE=$(tput setaf 4)

  echo_color "$BLUE" "[Info] - $1"
}

run_cmd() {
  local command="$1"
  local info_msg="$2"
  local success_msg="$3"
  local error_msg="$4"
  local use_sudo=${5:-0}
  local warning_msg="$6"
  local exit_on_fail=${7:-1}

  # Show the info msg if there is one
  if [ -n "$info_msg" ]; then
    info "$info_msg"
  fi

  # Run the command
  if [ "$use_sudo" -eq 1 ]; then
    command="sudo $command"
    eval "$command" 2> /dev/null
  else
    eval "$command" > /dev/null 2>&1
  fi

  if [ $? -eq 0 ]; then
    if [ -n "$success_msg" ]; then
      success "$success_msg"
    fi
  else
    error "$error_msg"
    if [ "$exit_on_fail" -eq 1 ]; then
      exit 1
    fi
  fi

  if [ -n "$warning_msg" ]; then
    warning "$warning_msg"
  fi
}

clear

# # Check if the script is runned as root
# if [ "$EUID" -ne 0 ]; then
#   error "this script must be run with sudo."
#   exit 1
# fi

run_cmd \
  "apt update" \
  "refreshing package information..." \
  "" \
  "failed to refresh package information." \
  1

DOCKER_INS=$(dpkg -l | grep docker.io)

KUBECTL_INS=$(dpkg -l | grep kubernetes-client)

# Install docker.io if it is not installed
if [ -z "$DOCKER_INS" ]; then
  run_cmd \
    "apt install -y docker.io" \
    "installing package docker.io..." \
    "successfully installed package docker.io." \
    "failed to install package docker.io." \
    1

  run_cmd \
    "usermod -aG docker $USER" \
    "adding current user to docker's group." \
    "" \
    "failed to add the current user to docker's group." \
    1 \
    "your current user has just been added to docker's group, \
you'll need to either restart your session or temporarily switch to the Docker group using the 'newgrp docker' command."
fi

# Install kubernetes-client if it is not installed
if [ -z "$KUBECTL_INS" ]; then
  run_cmd "apt install -y kubernetes-client" \
    "installing kubernetes-client..." \
    "successfully installed package kubernetes-client" \
    "failed to install package kubernetes-client." \
    1
fi

# Install ArgoCD CLI if it is not installed
if [ -z "$ARGOCD_INS" ]; then
  run_cmd \
    "wget -O /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64" \
    "installing ArgoCD client..." \
    "successfully installed ArgoCD client." \
    "failed to install ArgoCD client." \
    1
  
  run_cmd \
    "chmod +x /usr/local/bin/argocd" \
    "" \
    "" \
    "failed to set exec permission for ArgoCD client."
fi

# Installing k3d if it is not installed
if [ -z "$K3D_INS" ]; then
  run_cmd \
    "curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash" \
    "installing k3d..." \
    "successfully installed k3d." \
    "failed to install k3d." \
    1
fi

# Installing helm if not installed
if [ -z "$HELM_INS" ]; then
  run_cmd \
    "curl -fsSL  https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash " \
    "installing helm..." \
    "successfully installed helm." \
    "failed to install helm." \
    1
fi

# Creating a cluster
run_cmd \
  "k3d cluster create" \
  "creating k3d cluster" \
  "" \
  "failed to create cluster." \
  0 \
  "" \
  0

# Creating the namespaces
run_cmd \
  "kubectl create namespace argocd && kubectl create namespace dev && kubectl create namespace gitlab" \
  "creating namespaces 'argocd', 'dev' and 'gitlab'..." \
  "" \
  "failed to create namespaces 'argocd', 'dev' and 'gitlab'." \
  0 \
  "" \
  0

# Installing gitlab
run_cmd \
  "helm repo add gitlab https://charts.gitlab.io/" \
  "adding gitlab repo to helm..." \
  "" \
  "failed to add gitlab repo to helm."

run_cmd \
  "helm repo update"\
  "updating helm repo..." \
  "" \
  "failed to update helm repo."

run_cmd \
  "helm install gitlab gitlab/gitlab \
--namespace gitlab \
-f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
--set global.hosts.domain=mygitlab.com \
--set global.hosts.externalIP=0.0.0.0 \
--set global.hosts.https=false \
--set global.edition=ce \
--timeout 600s" \
  "installing gitlab..." \
  "" \
  "failed to install gitlab."

# run_cmd \
#   "while true; do kubectl wait --namespace gitlab --for=condition=ready pod --timeout=10s --all > /dev/null 2>&1 && break; sleep 2; done" \
#   "waiting for gitlab pods to be ready..." \
#   "gitlab pods ready." \
#   "some gitlab pods failed during the init process."

GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)

# # # Installing argocd
# run_cmd \
#   "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml" \
#   "installing ArgoCD in the 'argocd' namespace..." \
#   "" \
#   "failed to install ArgoCD."

# while true; do
#   kubectl wait --namespace argocd \
#     --for=condition=ready pod \
#     --timeout=10s --all > /dev/null 2>&1 && break
#   info "waiting all ArgoCD pods to be ready..."
#   sleep 10
# done

# # Port forward argocd
# run_cmd \
#   "kubectl port-forward svc/argocd-server -n argocd 8080:443 & disown" \
#   "starting port forwarding for ArgoCD server..." \
#   "port forwarding for ArgoCD server started successfully." \
#   "failed to start port forwarding for ArgoCD server."

# ADMIN_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# run_cmd \
#   "argocd login 127.0.0.1:8080 --username admin --password $ADMIN_PASS --insecure" \
#   "logging in to ArgoCD..." \
#   "logged in to ArgoCD successfully." \
#   "failed to log in to ArgoCD. Please check the ArgoCD server status."

# sleep 5

# # ArgoCD application creation using run_cmd
# run_cmd \
#   "argocd app create $APP_NAME --repo $REPO --path ./ --dest-server https://kubernetes.default.svc --dest-namespace dev --sync-policy automated" \
#   "creating ArgoCD application '$APP_NAME'..." \
#   "ArgoCD application '$APP_NAME' created successfully." \
#   "failed to create ArgoCD application '$APP_NAME'. Please check the repository URL and destination server."

# clear

# success "ArgoCD Successfullty Installed into k3d !\n
# ArgoCD Credentials -> Username: admin - Password: $ADMIN_PASS\n
# ArgoCD GUI available at address: https://localhost:8080/"
