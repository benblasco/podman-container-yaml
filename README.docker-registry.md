# Generating self signed and unencrypted certificates for the registry

The registry UI seems to want some working certificates for the registry in order to work, as there doesn't appear to be a `TLS_VERIFY=false` type parameter that can be set.

These are the instructions I followed to generate a self signed certificate with extensions, and to decrypt the private key:

How To Create a Self-Signed SSL Certificate in Linux
https://www.crazydomains.com.au/help/article/creating-a-self-signed-ssl-certificate-in-linux

Error creating TLS secret
https://access.redhat.com/solutions/5419501

How to create a certificate with Subject Alternative Name (SAN) extensions for OpenShift 4 mirror registry
https://access.redhat.com/solutions/6973542

## TL;DR... just give me the commands:

Generate a key (requires passphrase:
```
openssl genrsa -des3 -out self-ssl.key 2048
```

Generate the Certificate Signing Request (CSR)
Use the same passphrase as above when prompted, and fill out the details requested.
Note: Do not set a challenge password.
```
openssl req -new -key self-ssl.key -out self-ssl.csr
```

Create the OpenSSL X509v3 extensions file with Subject Alternative Names:
```
cat <<EOF > myserver.cnf
authorityKeyIdentifier=keyid,issuer
keyUsage=digitalSignature
extendedKeyUsage=serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = myserver.example.com             # change with the mirror FQDN e.g. micro.lan
DNS.2 = myserver                         # change with the mirror hostname e.g micro
EOF
```

Generate the certificate using the CSR, the extension file and the key
Enter the same passphrase as above when prompted.
```
openssl x509 -req -days 365 -in self-ssl.csr -extfile myserver.cnf -signkey self-ssl.key -out self-ssl.crt
```

Decrypt the private key
```
openssl rsa -in self-ssl.key -out self-ssl-unencrypted.key
```

Once you have done the above put the certificates in the right location according to the pod file definition so that they are used by the registry instance.

# Docker Registry garbage collection (image cleanup)

The Docker registry UI allows deletion of old image versions (tags), but does not actually do the garbage collection.

To delete old images from the Docker registry and clean up:
1. Delete them using the garbage bin icon in the Docker Registry UI
2. Run the garbage collector process in the container directly from the CLI of the container host:
    `podman exec -it <container name> bin/registry garbage-collect --delete-untagged /etc/docker/registry/config.yml`

More reading:
- [Optimizing your container registry: Understanding garbage collection in DOCR](https://www.digitalocean.com/blog/garbage-collection-digitalocean-container-registry)
- [Docker registry garbage collection](https://stackoverflow.com/questions/45046752/docker-registry-garbage-collection)
- [How to maintain a Private Docker Registry?](https://janethavishka.medium.com/how-to-maintain-a-private-docker-registry-d4f3d291e7d5)

## Tip: garbage collect when the disk is full and podman exec fails

If the disk is completely full, `podman exec` will fail because Podman cannot write its container state database. Use `nsenter` to bypass Podman and run the garbage collector directly inside the container's mount namespace:

```bash
# Find the registry process PID
pgrep -a -f "registry serve"

# Enter the container's mount namespace and run GC
sudo nsenter -t <PID> -m -- \
  /bin/registry garbage-collect --delete-untagged \
  /etc/docker/registry/config.yml
```

# Automated image cleanup with skopeo-registry-cleaner.sh

`files/docker-registry/skopeo-registry-cleaner.sh` is a bash script that iterates all repositories and tags in the registry and deletes any image older than a specified number of days, using `skopeo`. It handles both Docker Schema 2 and OCI manifests (e.g. bootc images), unlike tools built on the older `docker/distribution` library.

## Dependencies

- `skopeo` — image inspection and deletion
- `curl` — fetches the repository list from the registry `/v2/_catalog` endpoint
- `jq` — parses JSON responses

All three are standard on Fedora.

## Parameters

Both parameters are required; the script exits with an error and prints usage if either is missing.

| Parameter | Description |
|---|---|
| `--registry <URL>` | Full URL of the registry, including scheme (e.g. `https://nuc.lan:5000`) |
| `--days <N>` | Images created more than N days ago will be deleted |

All `skopeo` calls use `--tls-verify=false`, so self-signed certificates are handled automatically.

## Usage

```bash
skopeo-registry-cleaner.sh --registry https://nuc.lan:5000 --days 33
```

## Automated deployment via systemd timer

The script is deployed and scheduled automatically by `run-podman-quadlet-docker-registry.yml` using the `fedora.linux_system_roles.systemd` role. Two unit files in `files/docker-registry/` are deployed as user units for `bblasco`:

| File | Purpose |
|---|---|
| `docker-registry-cleaner.service` | Oneshot service: runs `skopeo-registry-cleaner.sh` then podman GC |
| `docker-registry-cleaner.timer` | Fires daily at 05:30; `Persistent=true` catches missed runs on boot |

The service depends on `docker-registry.service` (`Requires=` + `After=`) so it fails gracefully if the registry is not running. The script is installed to `/var/usrlocal/bin/skopeo-registry-cleaner.sh` (the writable overlay path used on bootc systems).

To check the timer status on a host:

```bash
systemctl --user status docker-registry-cleaner.timer
systemctl --user list-timers docker-registry-cleaner.timer
```

To run the cleanup manually without waiting for the timer:

```bash
systemctl --user start docker-registry-cleaner.service
journalctl --user -u docker-registry-cleaner.service -f
```

