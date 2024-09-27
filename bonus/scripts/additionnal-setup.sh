#!/bin/bash

DOMAIN=iot.fr

IP="127.0.0.1"

HOST="$IP gitlab.$DOMAIN"

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

GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)

# Adding domain to /etc/hosts
if grep -q "$HOST" /etc/hosts; then
  info "$HOST is already in /etc/hosts"
else
  info "adding domain to /etc/hosts"
  echo $HOST | sudo tee -a /etc/hosts
fi

kubectl port-forward svc/gitlab-gitlab-shell -n gitlab 32022:32022 2>&1 >/dev/null &

kubectl port-forward svc/gitlab-webservice-default -n gitlab 8081:8181 2>&1 >/dev/null &

clear

SSH=$(cat ~/.ssh/*.pub)

success "gitlab successfully installed into k3d !\n
Gitlab Credentials -> Username: root - Password: $GITLAB_PASSWORD\n
Gitlab GUI available at address: http://gitlab.$DOMAIN:8081/\n
Your SSH public key: $SSH"
