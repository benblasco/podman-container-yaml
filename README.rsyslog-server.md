# Red Hat container registry credentials for rsyslog server container

Easiest to pass them on the command line when running the playbook, like this:

```
ansible-playbook run-podman-quadlet-rsyslog-server.yml -e "podman_registry_username=<your registry user>" -e "podman_registry_password=<your registry password>"

```
