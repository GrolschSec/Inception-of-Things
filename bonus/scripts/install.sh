#!/bin/bash

ARGOCD_INS=$(command -v argocd)

K3D_INS=$(command -v k3d)

HELM_INS=$(command -v helm)

APP_NAME="playground-app"

DOMAIN=iot.fr

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

# Installing helm if not installed
if [ -z "$HELM_INS" ]; then
  run_cmd \
    "curl -fsSL  https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash " \
    "installing helm..." \
    "successfully installed helm." \
    "failed to install helm." \
    1
fi

# Creating the namespaces
run_cmd \
  "kubectl create namespace gitlab" \
  "creating namespaces 'gitlab'..." \
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
--set global.hosts.domain=$DOMAIN \
--set global.hosts.externalIP=0.0.0.0 \
--set global.hosts.https=false \
--set global.edition=ce \
--timeout 600s" \
  "installing gitlab..." \
  "" \
  "failed to install gitlab."

info "Wait for gitlab pods to be ready then run 'additional-setup.sh'"
