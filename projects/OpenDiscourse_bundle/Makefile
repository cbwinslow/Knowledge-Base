.PHONY: discover local remote

discover:
\tansible-playbook -i ansible/inventory.ini ansible/playbooks/discover.yml

local: discover
\tansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml -l local

remote: discover
\tansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml -l db,app
