# Docker Aliases

# Container management
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstart='docker start'
alias dstop='docker stop'
alias drestart='docker restart'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'

# Docker Compose
alias dc='docker-compose'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dcrestart='docker-compose restart'
alias dclogs='docker-compose logs -f'
alias dcps='docker-compose ps'
alias dcbuild='docker-compose build'

# Cleanup
alias dprune='docker system prune -f'
alias dprunea='docker system prune -a -f'
alias dcprune='docker container prune -f'
alias diprune='docker image prune -f'
alias dvprune='docker volume prune -f'

# Network
alias dnet='docker network ls'
alias dnetinspect='docker network inspect'

# Volume
alias dvol='docker volume ls'
alias dvolinspect='docker volume inspect'

# Stats and info
alias dstats='docker stats'
alias dinfo='docker info'
alias dsysdf='docker system df'
