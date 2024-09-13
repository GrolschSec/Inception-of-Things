#!/bin/bash

DOMAIN="gitlab-webservice-default.gitlab.svc.cluster.local:8181"

REPO="pbeheyt42-IoT"

USER="root"

APP="playground-gitlab"

argocd app create $APP \
    --repo "http://${DOMAIN}/${USER}/${REPO}.git" \
    --path . \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace dev \
    --sync-policy auto
