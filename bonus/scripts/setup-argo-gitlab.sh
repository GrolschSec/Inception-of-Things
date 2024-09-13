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