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
# Home Assistant MCP server

The home assistant pod contains this unofficial MCP server:
https://github.com/homeassistant-ai/ha-mcp

Setup guide:
https://homeassistant-ai.github.io/ha-mcp/setup/

Troubleshooting guide:
https://homeassistant-ai.github.io/ha-mcp/faq/


## Home Assistant MCP server client configuration

For cursor, you need the following client configuration:
```
{
  "mcpServers": {
    "home-assistant": {
      "url": "http://<MCP SERVER URL>:<MCP SERVER PORT>/mcp",
      "transport": "http"
    }
  }
}
```
