# Signal CLI REST API

The Signal API runs on `micro.lan:9922`. After deploying, link your Signal number by visiting:

```
http://micro.lan:9922/v1/qrcodelink?device_name=signal-api
```

Then scan the QR code in the Signal app under Settings → Linked Devices.

## Send a test message

```bash
curl -X POST -H "Content-Type: application/json" \
  'http://micro.lan:9922/v2/send' \
  -d '{"message": "Hello Worlf", "number": "+61439655641", "recipients": ["+61439655641"]}'
```

A successful response returns HTTP 201 with a `{"timestamp":...}` body.

## Service failure notifications

Install the shared notify script and `signal-failure-notify@.service` handler (per systemd user) on homelab hosts:

```bash
cp group_vars/all/signal-notify.yml.example group_vars/all/signal-notify.yml  # set webhook_url, signal_number, signal_group_id
ansible-playbook -i hosts enable-service-failure-notifications.yml
```

Uses the same `signal-notify.yml` variables as [backups-personal](https://github.com/benblasco/backups-personal) (`backups-config.yml`). The playbook targets `micro.lan`, `nuc.lan`, `opti.lan`, and `hex.lan`, and installs handlers for `root` (system), `bblasco`, and `media`.

To notify on a failed unit, add to that unit’s `[Unit]` section (when you are ready):

```ini
OnFailure=signal-failure-notify@%n.service
```

Per-service `OnFailure=` is added manually on quadlet `.kube` files as needed (e.g. `esphome.kube`); optional templated kube files may follow later.

### Manual test

```bash
MONITOR_UNIT=homepage.service MONITOR_SERVICE_RESULT=exit-code MONITOR_EXIT_STATUS=1 \
  MONITOR_INVOCATION_ID="$(systemctl --user show homepage.service -p InvocationID --value)" \
  /var/usrlocal/bin/systemd-failure-notify.sh
```

If `signal-api.service` is down, the webhook call fails silently (`curl -sf`).

More API examples: [signal-cli-rest-api EXAMPLES.md](https://github.com/bbernhard/signal-cli-rest-api/blob/master/doc/EXAMPLES.md).

## A note on group creation in Signal and retrieving the Group ID string

If you create a group in the Signal app (e.g. via your phone) and want to send notifications to that group, you will need to synchronise the Signal API container before being able to retrieve the Group ID (which will look something like `group.UjlLNG4wNkpFY2kyc0I2a21oUWpPbU31T1J6QnI4blRxN2t2cnBNTHgvVT0=`).

Please see Git issue [listGroups not showing new groups
#1602](https://github.com/AsamK/signal-cli/issues/1602)

Synchronise the container as follows:
```
podman exec -it signal-api-signal-api /bin/bash
signal-cli --config /home/.local/share/signal-cli sendSyncRequest
```

Then grab the list of groups to fetch the Group ID with the following command:
```
curl -X GET -H "Content-Type: application/json" 'http://<Signal API container host>:9922/v1/groups/<your phone number>' | jq 
```