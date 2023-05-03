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

# Ben's Home Assistant container Bluetooth config

Rough notes on getting Bluetooth working here for posterity

1. NOT REQUIRED edit the bluetooth.conf to allow me as a user all the relevant privileges?

2. sudo chown -R bblasco:bblasco /home/bblasco/.local/share/containers/storage/volumes/h3-config/
This is due to the following bug:
"podman run is not honoring --userns=keep-id --user=1000:1000 settings while creating volumes"
https://github.com/containers/podman/issues/16741

4. Make the relevant SELinux changes on the system
	1. You see something like this in /var/log/audit/audit.log: `type=USER_AVC msg=audit(1683117204.775:2041): pid=817 uid=81 auid=4294967295 ses=4294967295 subj=system_u:system_r:system_dbusd_t:s0-s0:c0.c1023 msg='avc:  denied  { send_msg } for  scontext=system_u:system_r:bluetooth_t:s0 tcontext=unconfined_u:system_r:spc_t:s0 tclass=dbus permissive=0 exe="/usr/bin/dbus-broker" sauid=81 hostname=? addr=? terminal=?'UID="dbus" AUID="unset" SAUID="dbus"`
	2. Check what the issue is: 
```[root@opti ~]# grep tooth /var/log/audit/audit.log | tail -1 | audit2why
type=USER_AVC msg=audit(1683117372.225:2274): pid=817 uid=81 auid=4294967295 ses=4294967295 subj=system_u:system_r:system_dbusd_t:s0-s0:c0.c1023 msg='avc:  denied  { send_msg } for  scontext=system_u:system_r:bluetooth_t:s0 tcontext=unconfined_u:system_r:spc_t:s0 tclass=dbus permissive=0 exe="/usr/bin/dbus-broker" sauid=81 hostname=? addr=? terminal=?'UID="dbus" AUID="unset" SAUID="dbus"

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
```

    3. Generate the module:
```
[root@opti ~]# grep tooth /var/log/audit/audit.log | tail -1 | audit2allow -a -M bluetooth_homeassistant
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i bluetooth_homeassistant.pp
```

