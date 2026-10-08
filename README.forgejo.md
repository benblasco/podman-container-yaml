# Forgejo and Actions runners

Kube quadlets on lab hosts. Deploy with [`run-podman-quadlet-forgejo.yml`](run-podman-quadlet-forgejo.yml) (two plays: server, then runners).

| Piece | Inventory group | Unit | Files |
|-------|-----------------|------|--------|
| Forgejo app | `[forgejo_server]` | `forgejo.service` | `pod-forgejo.yml`, `forgejo.kube` |
| Actions runner | `[forgejo_runner]` | `forgejo-runner.service` | `pod-forgejo-runner.yml.j2`, `forgejo-runner.kube.j2` |

Server today: **opti.lan** (`codeberg.org/forgejo/forgejo:15-rootless`, ports **3000** / **2222**, volume `forgejo-data`). Runners use `data.forgejo.org/forgejo/runner:13`. **Rootless** runner kube quads use pasta networking (see `forgejo.kube`); **rootful** omits pasta (Podman default pod network).

## Rootless vs rootful runner

Each runner host **must** define `podman_run_as_user` and `podman_run_as_group` in `host_vars/<host>/forgejo-runner.yml` (see [example](host_vars/opti.lan/forgejo-runner.yml.example)). The runner play does not set those variables (the server play still pins `bblasco` for Forgejo app only). Shared URL for all runners: `forgejo_instance_url` in [`group_vars/forgejo_runner/forgejo.yml`](group_vars/forgejo_runner/forgejo.yml) (inventory group `[forgejo_runner]` in [`hosts`](hosts)—underscore, not `forgejo-runner`).

| `podman_run_as_user` | Quadlet scope | Job-container Podman API |
|----------------------|---------------|---------------------------|
| `bblasco` (typical rootless) | User systemd (`systemctl --user`) | User `podman.socket` → `/run/user/<uid>/podman/podman.sock` (optional `podman_socket_uid`, default 1000) |
| `root` | System systemd (`systemctl`) | System `podman.socket` → `/run/podman/podman.sock` |

Pod and kube templates branch on `podman_run_as_user == 'root'` (socket path, container `runAsUser`, `UserNS`/`Network` in `forgejo-runner.kube.j2`). **Rootful** runner containers run as UID 0 with `spc_t` so they can use the system Podman API socket under SELinux enforcing; **rootless** runs as UID 1000 with the same `spc_t` for the user socket. **opti.lan** uses a **rootful** runner (`podman_run_as_user: root` in its `forgejo-runner.yml`).

Switching a host between rootless and rootful uses a **new** Podman storage graph for `forgejo-runner-data` (no automatic volume migration). Re-deploy recreates `/data/config.yml` and `/data/.runner` from Ansible templates if the volume is empty.

**Podman API socket:** The runner process only schedules work; each workflow job runs in a separate container. Forgejo Runner uses the Docker-compatible API (`DOCKER_HOST`) to create those containers. Without the matching socket, jobs fail at startup. See [Runner installation — container environment](https://forgejo.org/docs/latest/admin/actions/runner-installation/#setting-up-the-container-environment) and [Utilizing Docker within Actions](https://forgejo.org/docs/latest/admin/actions/docker-access/).

Pod name on each runner host: **`{{ inventory_hostname_short }}-runner`** (e.g. `opti-runner`). Central Forgejo URL for all runners: `forgejo_instance_url` in group vars.

## Registration

1. Complete Forgejo install at `http://opti.lan:3000` if needed.
2. **Site administration → Actions → Runners** → create a runner named like `opti-runner` for that host.
3. Copy [example](host_vars/opti.lan/forgejo-runner.yml.example) to `host_vars/<host>/forgejo-runner.yml`. Set **uuid**, **token**, and **podman_run_as_user** / **podman_run_as_group**. Add the host to `[forgejo_runner]` in [`hosts`](hosts). Do not use `forgejo-runner register` with that token—it is not the one-shot registration token; the playbook writes `/data/.runner` (registration) and `/data/config.yml` (labels, container options) on each deploy.
4. `ansible-playbook run-podman-quadlet-forgejo.yml --ask-become-pass`

Workflows for [fedora-server-bootc](https://github.com/benblasco/fedora-server-bootc): `runs-on: fedora-server-bootc` (`quay.io/containers/aio` job image; see comments in `run-podman-quadlet-forgejo.yml`). Host `/etc/containers/registries.conf.d` must allow `micro.lan:5000` and `nuc.lan:5000` as insecure.

After changing runner labels or `container:` options, re-run the playbook and restart the runner unit:

- Rootful: `systemctl restart forgejo-runner.service`
- Rootless: `sudo -u bblasco XDG_RUNTIME_DIR=/run/user/1000 systemctl --user restart forgejo-runner.service`

If the volume has a stale config, fix `/data/config.yml` on volume `forgejo-runner-data` or remove it before restart.

### Moving opti.lan to a rootful runner

1. Stop the old user runner: `sudo -u bblasco XDG_RUNTIME_DIR=/run/user/1000 systemctl --user stop forgejo-runner.service`
2. Set `podman_run_as_user: root` and `podman_run_as_group: root` in `host_vars/opti.lan/forgejo-runner.yml`
3. Re-run the forgejo playbook; remove stale user quadlet files under `~bblasco/.config/containers/systemd/` if the role left them
4. Optionally disable `podman.socket` in bblasco’s user manager if nothing else needs the rootless API

## Verify

Rootful runner on opti.lan:

```bash
ssh opti.lan 'systemctl is-active podman.socket forgejo-runner.service; systemctl --user is-active forgejo.service'
ssh opti.lan 'getenforce; podman --url unix:///run/podman/podman.sock ps'
```

Rootless runner (example):

```bash
ssh <host> 'sudo -u bblasco XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-active forgejo-runner.service'
getenforce
```
