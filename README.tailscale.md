# Tailscale container authentication key

## Generate a new auth key after expiry

Instructions:
https://tailscale.com/kb/1085/auth-keys

URL:
https://login.tailscale.com/admin/settings/keys

Example key: `tskey-auth-kf5TBXe2mA21CNTRL-8T6xic8qhBAzfJycEKEBAAiZH9Zp4oSRE`

Then take that auth key and put it in the container pod definition

```
      env:
        - name: TS_AUTHKEY
          value: tskey-auth-kFwx5M8WTB21CNTRL-SDH44CBqKiizNLK3W7R2jizV4vUZ6BL1
```

## Review and approve route settings

If you add a route to your configuration you have to review and approve it
in the Tailscale Web UI.

1. Open the Tailscale admin console
2. Find machine tailscale-micro (or whichever node is advertising the route
3. Go to Edit route settings (or Subnet routes)
4. Approve the routes under review
5. Ensure your client has AcceptRoutes: True
