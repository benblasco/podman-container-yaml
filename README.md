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

# Boot startup stagger

At boot, every enabled Quadlet service is pulled in by `default.target` and tends to start at once. On a host running many pods, that creates a CPU spike that can cause systemd to time out units (default 90s) or exhaust the start-retry limit, leaving services in a `failed` state until someone notices.

Each `.kube` file in [`files/kube/`](files/kube/) configures three systemd directives to reduce this:

| Directive | Purpose |
|-----------|---------|
| `RandomizedDelaySec` | Waits a random interval between 0 and N seconds before starting, spreading load across boot |
| `TimeoutStartSec` | Maximum time systemd waits for `podman kube play` to become ready (heavy pods need more than the 90s default) |
| `StartLimitBurst` | Number of start attempts allowed within `StartLimitIntervalSec` before systemd gives up (raised from 3 to 5) |

## Priority tiers

Tier **1** is highest priority (starts earliest); tier **4** is lowest (starts latest). Each `.kube` file includes a `# Boot stagger: Tier N` comment.

| Tier | Typical delay | Services |
|------|---------------|----------|
| 1 | 30–60s | Pi-hole, Tailscale, Signal API, Uptime Kuma, Home Assistant, UniFi |
| 2 | 90s | Docker Registry, Docker Registry UI, Jenkins, Homepage, iSponsorBlockTV |
| 3 | 120–150s | Transmission, ESPHome, Arrsuite |
| 4 | 240s | BentoPDF, Boot server, NetAlertX, Rsyslog-server, HashiCorp Vault |

### Per-service values

| Tier | Service | `RandomizedDelaySec` | `TimeoutStartSec` |
|------|---------|---------------------|-------------------|
| 1 | Pi-hole | 30s | 180s |
| 1 | Tailscale | 30s | 180s |
| 1 | Signal API | 45s | 180s |
| 1 | Uptime Kuma | 45s | 180s |
| 1 | Home Assistant | 60s | 300s |
| 1 | UniFi | 60s | 600s |
| 2 | Docker Registry | 90s | 180s |
| 2 | Docker Registry UI | 90s | 180s |
| 2 | Jenkins | 90s | 600s |
| 2 | Homepage | 90s | 240s |
| 2 | iSponsorBlockTV | 90s | 180s |
| 3 | Transmission | 120s | 180s |
| 3 | ESPHome | 150s | 180s |
| 3 | Arrsuite | 150s | 300s |
| 4 | BentoPDF | 240s | 180s |
| 4 | Boot server | 240s | 180s |
| 4 | NetAlertX | 240s | 180s |
| 4 | Rsyslog-server | 240s | 180s |
| 4 | HashiCorp Vault | 240s | 180s |

To change a service's tier, edit its `.kube` file (tier comment, `RandomizedDelaySec`, and `TimeoutStartSec`), then redeploy with the matching `run-podman-quadlet-*.yml` playbook.

Verify on a deployed host:

```bash
systemctl --user show pihole.service -p RandomizedDelaySec,TimeoutStartSec,StartLimitBurst
```

# Pod/container healthchecks

All the containers running here have liveness probes configured. You can check the health of the container with a command like: 

`watch -n 5 "podman inspect <container name> --format='{{json .State.Health}}'"`

You can also check what the currently running health check is via:

`podman inspect <container name> --format '{{json .Config.Healthcheck}}'`

# Additional documentation

- [Home Assistant (Bluetooth, MCP server)](README.home-assistant.md)
- [ESPHome storage layout and cleanup](README.esphome.md)
- [Tailscale container authentication key](README.tailscale.md)
- [Rsyslog server — Red Hat registry credentials](README.rsyslog-server.md)
- [Signal CLI REST API](README.signal-api.md) (includes [failure notifications](README.signal-api.md#service-failure-notifications) via `enable-service-failure-notifications.yml`)
- [Jenkins backups](README.jenkins.md)
- [Docker registry certificates and garbage collection](README.docker-registry.md)
