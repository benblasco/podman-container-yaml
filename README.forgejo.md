# Forgejo and Actions runners

Rootless kube quadlets on lab hosts. Deploy with [`run-podman-quadlet-forgejo.yml`](run-podman-quadlet-forgejo.yml) (two plays: server, then runners).

| Piece | Inventory group | Unit | Files |
|-------|-----------------|------|--------|
| Forgejo app | `[forgejo_server]` | `forgejo.service` | `pod-forgejo.yml`, `forgejo.kube` |
| Actions runner | `[forgejo_runner]` | `forgejo-runner.service` | `pod-forgejo-runner.yml.j2`, `forgejo-runner.kube` |

Server today: **opti.lan** (`codeberg.org/forgejo/forgejo:15-rootless`, ports **3000** / **2222**, volume `forgejo-data`). Runners use `data.forgejo.org/forgejo/runner:6.2.0` and pasta networking (see `transmission.kube`).

**Podman API socket:** The runner process only schedules work; each workflow job runs in a separate container. Forgejo Runner uses the Docker-compatible API (`DOCKER_HOST`) to create those containers. On rootless hosts we enable `podman.socket` for the quadlet user and mount `…/podman/podman.sock` into the runner pod. Without that socket, jobs fail at startup. See [Runner installation — container environment](https://forgejo.org/docs/latest/admin/actions/runner-installation/#setting-up-the-container-environment) and [Utilizing Docker within Actions](https://forgejo.org/docs/latest/admin/actions/docker-access/).

Pod name on each runner host: **`{{ inventory_hostname_short }}-runner`** (e.g. `opti-runner`). Central Forgejo URL for all runners: [`group_vars/forgejo_runner/forgejo.yml`](group_vars/forgejo_runner/forgejo.yml) (`forgejo_instance_url`).

## Registration

1. Complete Forgejo install at `http://opti.lan:3000` if needed.
2. **Site administration → Actions → Runners** → create a runner named like `opti-runner` for that host.
3. Copy the **configuration file** values (`url`, `uuid`, `token`) into `host_vars/<host>/forgejo-runner.yml` (see [example](host_vars/opti.lan/forgejo-runner.yml.example)). Add the host to `[forgejo_runner]` in [`hosts`](hosts). Do not use `forgejo-runner register` with that token—it is not the one-shot registration token; the playbook writes `server.connections` and a matching `/data/.runner` state file on each deploy.
4. `ansible-playbook run-podman-quadlet-forgejo.yml --ask-become-pass`

Workflows for [fedora-server-bootc](https://github.com/benblasco/fedora-server-bootc): `runs-on: fedora-server-bootc` (`quay.io/containers/aio` job image; see comments in `run-podman-quadlet-forgejo.yml`). Host `/etc/containers/registries.conf.d` must allow `micro.lan:5000` and `nuc.lan:5000` as insecure.

After changing runner labels or `container:` options, re-run the playbook and `systemctl --user restart forgejo-runner.service`. If the volume has a stale config, fix `/data/config.yml` on volume `forgejo-runner-data` or remove it before restart.

## Verify

```bash
ssh opti.lan 'sudo -u bblasco XDG_RUNTIME_DIR=/run/user/1000 systemctl --user status forgejo.service forgejo-runner.service'
getenforce
```
