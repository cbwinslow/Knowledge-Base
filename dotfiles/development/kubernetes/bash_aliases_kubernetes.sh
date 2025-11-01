# Kubernetes Aliases

# kubectl shortcuts
alias k='kubectl'
alias kx='kubectl exec -it'
alias kl='kubectl logs -f'

# Get resources
alias kgp='kubectl get pods'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kgns='kubectl get namespaces'
alias kga='kubectl get all'
alias kgcm='kubectl get configmaps'
alias kgsec='kubectl get secrets'

# Describe resources
alias kdp='kubectl describe pod'
alias kdd='kubectl describe deployment'
alias kds='kubectl describe service'
alias kdn='kubectl describe node'

# Delete resources
alias kdel='kubectl delete'
alias kdelp='kubectl delete pod'
alias kdeld='kubectl delete deployment'
alias kdels='kubectl delete service'

# Logs
alias klf='kubectl logs -f'
alias klp='kubectl logs -f -p'

# Apply and create
alias kapp='kubectl apply -f'
alias kcreate='kubectl create'
alias kdel='kubectl delete -f'

# Context and namespace
alias kctx='kubectl config get-contexts'
alias kuse='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'
alias kcurrent='kubectl config current-context'

# Scale and rollout
alias kscale='kubectl scale'
alias krollout='kubectl rollout'
alias krestart='kubectl rollout restart'
alias krollback='kubectl rollout undo'
alias kstatus='kubectl rollout status'

# Port forward
alias kpf='kubectl port-forward'

# Top
alias ktop='kubectl top'
alias ktopn='kubectl top nodes'
alias ktopp='kubectl top pods'

# Events
alias kevents='kubectl get events --sort-by=.metadata.creationTimestamp'

# Exec shortcuts
alias kbash='kubectl exec -it -- /bin/bash'
alias ksh='kubectl exec -it -- /bin/sh'

# Watch
alias kwatch='watch kubectl get'
alias kwatchp='watch kubectl get pods'
