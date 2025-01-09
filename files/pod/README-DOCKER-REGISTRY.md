# Generating self signed and unencrypted certificates for the registry

The registry UI seems to want some working certificates for the registry in order to work, as there doesn't appear to be a `TLS_VERIFY=false` type parameter that can be set.

These are the instructions I followed to generate a self signed certificate and to decrypt the private key:

How To Create a Self-Signed SSL Certificate in Linux
https://www.crazydomains.com.au/help/article/creating-a-self-signed-ssl-certificate-in-linux

Error creating TLS secret
https://access.redhat.com/solutions/5419501

## TL;DR... just give me the commands:

```
openssl genrsa -des3 -out self-ssl.key 2048

openssl req -new -key self-ssl.key -out self-ssl.csr

openssl x509 -req -days 365 -in self-ssl.csr -signkey self-ssl.key -out self-ssl.crt

openssl rsa -in self-ssl.key -out self-ssl-unencrypted.key
```

Once you have done the above put the certificates in the right location according to the pod file definition so that they are used by the registry instance