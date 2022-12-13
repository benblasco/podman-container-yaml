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
