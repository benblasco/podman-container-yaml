# podman-container-yaml
Kubernetes YAML files and Ansible playbooks for use with Podman Linux System Role
The system role is documented here: https://github.com/linux-system-roles/podman

# Requirements/pre-requisites
- Ansible installed
- Podman 4.2 or newer installed

Follow the instructions in requirements.yml to install the relevant Ansible pre-requisites.

# Use

Kubernetes spec files are defined with names like `pod-<container name>.yml`

Ansible playbooks are defined with names like `run-<container name>.yml`

Execute the playbook by running:
`ansible-playbook podman-<container name>.yml --ask-become-pass`
or similar

Note: if you need to authenticate to the registry for the container, the lazy way via the command line is:
`ansible-playbook podman-<container name>.yml --ask-become-pass -e podman_registry_username=<username> -e podman_registry_password=<password>`

# Quadlet use

Key info from https://www.redhat.com/sysadmin/multi-container-application-podman-quadlet
Also great info if you run `man podman-systemd.unit`

## Steps for a rootless container
1. Create a kubernetes spec file called <filename>.kube
2. Copy the file to ~/.config/containers/systemd/
3. Run `loginctl enable-linger <user>`
4. Check that lingering is enabled `loginctl show-user <user>`
5. Run `systemctl --user daemon-reload`
6. Check the service with `systemctl --user status <filename>.service`
7. Don't forget to enable any firewall ports that need to be enabled

# Pod/container healthchecks

All the containers running here have liveness probes configured. You can check the health of the container with a command like: 

`watch -n 5 "podman inspect <container name> --format='{{json .State.Health}}'"`

You can also check what the currently running health check is via:

`podman inspect <container name> --format '{{json .Config.Healthcheck}}'`

# Additional documentation

- [Home Assistant (Bluetooth, MCP server)](README.home-assistant.md)
- [Tailscale container authentication key](README.tailscale.md)
- [Rsyslog server — Red Hat registry credentials](README.rsyslog-server.md)
- [Signal CLI REST API](README.signal-api.md)
- [Jenkins backups](README.jenkins.md)
- [Docker registry certificates and garbage collection](README.docker-registry.md)
