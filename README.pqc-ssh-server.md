# pqc-ssh-server (nuc.lan)

Post-quantum capable SSH server ([upstream repo](https://github.com/benblasco/pqc-ssh-server)) running as a rootless
Podman kube quadlet on **nuc.lan**. Main image: `micro.lan:5000/pqc-ssh-server:latest`; init containers use
`registry.access.redhat.com/hi/core-runtime:latest-builder` (or `pqc_ssh_init_image` in host_vars).

Pod spec: [`templates/pod/pod-pqc-ssh-server.yml.j2`](templates/pod/pod-pqc-ssh-server.yml.j2). Systemd unit:
[`files/kube/pqc-ssh-server.kube`](files/kube/pqc-ssh-server.kube). Deploy: [`run-podman-quadlet-pqc-ssh-
server.yml`](run-podman-quadlet-pqc-ssh-server.yml).

## Prerequisites

- nuc.lan can pull from `micro.lan:5000` (insecure registry config as in [README.forgejo.md](README.forgejo.md)).
- Use a current hardened **`pqc-ssh-server`** image from that registry (rebuild and push from
  [pqc-ssh-server](https://github.com/benblasco/pqc-ssh-server) after upstream changes).
- **bblasco** on nuc can pull init image: `podman login registry.access.redhat.com` then
  `podman pull registry.access.redhat.com/hi/core-runtime:latest-builder` (or override `pqc_ssh_init_image` to a
  mirrored tag on `micro.lan:5000`).
- Registry image built with `SSH_UID` / `SSH_GID` matching **bblasco** on nuc (or set `pqc_ssh_uid` / `pqc_ssh_gid` in
  host_vars to match the image). Upstream build uses chunkah; see the pqc-ssh-server `Containerfile` header.

## Setup (one time)

1. Copy [`host_vars/nuc.lan/pqc-ssh-server.yml.example`](host_vars/nuc.lan/pqc-ssh-server.yml.example) to
1.   `host_vars/nuc.lan/pqc-ssh-server.yml`.
2. Copy [`files/pqc-ssh-server/nuc.lan-authorized_keys.example`](files/pqc-ssh-server/nuc.lan-authorized_keys.example)
2.   to `files/pqc-ssh-server/nuc.lan-authorized_keys` and add your Ed25519 **public** key line(s), or point
2.   `pqc_ssh_authorized_keys_file` at another path on the Ansible control machine.

## Deploy

```bash
ansible-playbook run-podman-quadlet-pqc-ssh-server.yml --ask-become-pass
```

After a new image is pushed to the registry, re-run the playbook (or `podman pull micro.lan:5000/pqc-ssh-server:latest`
on nuc as **bblasco**, then `systemctl --user restart pqc-ssh-server.service`) so the main container picks up the
new image (`command: [/usr/sbin/sshd, -D]` in the pod spec; no image entrypoint).

If the registry requires authentication:

```bash
ansible-playbook run-podman-quadlet-pqc-ssh-server.yml --ask-become-pass \
  -e podman_registry_username=<user> -e podman_registry_password=<password>
```

## Connect

```bash
ssh -p 22222 -i "${HOME}/.ssh/id_ed25519" sshuser@nuc.lan
```

## Updating authorized keys

Edit the file referenced by `pqc_ssh_authorized_keys_file`, then re-run the playbook. An init container rewrites the
`pqc-ssh-authorized-keys` volume on each pod start; the playbook restarts `pqc-ssh-server.service` so changes apply.

If the unit previously hit `StartLimitBurst`, reset before redeploying on nuc:

```bash
systemctl --user reset-failed pqc-ssh-server.service
```

## Volumes

| Podman volume | Mount | Purpose |
|---------------|-------|---------|
| `pqc-ssh-hostkeys` | `/var/lib/sshd` | Persistent Ed25519 server host key (init `prepare-hostkeys` creates it before `sshd` starts) |
| `pqc-ssh-authorized-keys` | `/home/sshuser/.ssh` | Client public keys (init `seed-authorized-keys`; `sshd` is pubkey-only and does not write here) |

Do **not** add `UserNS=keep-id` to the quadlet; `sshd` must run as root inside the container user namespace (see
upstream README).

The main container runs **`/usr/sbin/sshd -D`** (pod `command`; hardened image has no shell entrypoint). Init
**`prepare-hostkeys`** (builder image) runs first and creates `ssh_host_ed25519_key` on the PVC before `sshd` starts.
Do **not** set `readOnly: true` on the `pqc-ssh-authorized-keys` mount in the same pod as
the init container that seeds it—Podman kube play can apply read-only to the whole volume and break init (see
troubleshooting).

## Troubleshooting

Use the **user** systemd manager and journal (`journalctl --user -u pqc-ssh-server.service`).

| Log / symptom | What to check |
|---------------|----------------|
| `seed-authorized-keys` + `authorized_keys: Permission denied` | `readOnly` on shared PVC; fix pod YAML, redeploy |
| `prepare-hostkeys` or `Saving key … failed: Permission denied` | `pqc-ssh-hostkeys` volume not writable (often wrong ownership from an earlier failed run) |
| Main container exits immediately / no listen on 22 | Host key missing on PVC; check `prepare-hostkeys` logs—main image does not run `ssh-keygen` |
| `container restart` ~every 90s, journal `unhealthy`, SSH on 22222 works between restarts | Do not use `livenessProbe.tcpSocket` on Podman: it becomes `nc -z localhost 22` and minimal images lack `nc`—see comment in `pod-pqc-ssh-server.yml.j2` |

```bash
systemctl --user status pqc-ssh-server.service
journalctl --user -u pqc-ssh-server.service -n 50 --no-pager
podman logs pqc-ssh-server-prepare-hostkeys 2>&1 | tail -20
podman logs pqc-ssh-server-pqc-ssh-server 2>&1 | tail -20
podman volume inspect pqc-ssh-hostkeys pqc-ssh-authorized-keys
getenforce
```

### Fix a broken `pqc-ssh-hostkeys` volume (nuc, as `bblasco`)

Inspect ownership on the host:

```bash
MP=$(podman volume inspect pqc-ssh-hostkeys --format '{{.Mountpoint}}')
ls -la "$MP"
```

If the directory is not owned by your user or is not writable, stop the service and repair (keeps existing keys if files
are only permission-wrong):

```bash
systemctl --user stop pqc-ssh-server.service
podman unshare chown -R "$(id -u):$(id -g)" "$MP"
chmod 700 "$MP"
systemctl --user start pqc-ssh-server.service
```

If the volume is empty or corrupt and you accept a **new server host key** (clients must update `known_hosts`):

```bash
systemctl --user stop pqc-ssh-server.service
podman volume rm pqc-ssh-hostkeys
systemctl --user start pqc-ssh-server.service
```

Then redeploy or restart so init `prepare-hostkeys` recreates the key.

## Verify on nuc.lan

```bash
systemctl --user status pqc-ssh-server.service
podman ps --filter name=pqc-ssh-server
podman exec -u sshuser pqc-ssh-server-pqc-ssh-server test -r /home/sshuser/.ssh/authorized_keys && echo OK
ss -tlnp | grep 22222
getenforce
```

## References

- [pqc-ssh-server README](https://github.com/benblasco/pqc-ssh-server/blob/main/README.md)
- [SSH Post-Quantum Cryptography Configuration Guide](https://access.redhat.com/articles/7026851) (linked from upstream)
