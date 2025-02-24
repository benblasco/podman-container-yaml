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
cat <<EOF > myserver.cnf
authorityKeyIdentifier=keyid,issuer
keyUsage=digitalSignature
extendedKeyUsage=serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = myserver.example.com             # change with the mirror FQDN e.g. micro.lan
DNS.2 = myserver                         # change with the mirror hostname e.g micro
EOF

Generate the certificate using the CSR, the extension file and the key
Enter the same passphrase as above when prompted.
```
openssl x509 -req -days 365 -in self-ssl.csr -signkey self-ssl.key -out self-ssl.crt
openssl x509 -req -days 365 -in self-ssl.csr -extfile myserver.cnf -signkey self-ssl.key -out self-ssl.crt
```

Decrypt the private key
```
openssl rsa -in self-ssl.key -out self-ssl-unencrypted.key
```

Once you have done the above put the certificates in the right location according to the pod file definition so that they are used by the registry instance.
