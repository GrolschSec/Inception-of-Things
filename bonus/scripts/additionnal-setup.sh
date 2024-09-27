#!/bin/bash

DOMAIN=iot.fr

IP="127.0.0.1"

HOST="$IP gitlab.$DOMAIN"

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
