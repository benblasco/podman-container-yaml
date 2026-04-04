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
