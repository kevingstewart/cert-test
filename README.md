# Curated F5 CA Bundle Installer

Installs a new curated F5 CA bundle onto a BIG-IP, and optionally updates any CA Bundle Manager configurations to use this new trusted CA bundle.

Access the BIG-IP shell as an admin and run the following commands:

```bash
curl -sk "https://raw.githubusercontent.com/kevingstewart/cert-test/refs/heads/main/f5-ca-bundle-installer.sh" -o f5-ca-bundle-installer.sh && chmod +x f5-ca-bundle-installer.sh
./f5-ca-bundle-installer.sh
```
