# 🔐 Create Your Own SSL Certificate Authority (Root + Intermediate + Domain) with OpenSSL | Step-by-Step Bash Automation

> Auto SSL Generator with OpenSSL (Root CA + Intermediate CA + Domain Cert) Perfect for HomeLab and Intranet Servers.

This project provides a **Bash script** to automatically generate:

- ✅ Root Certificate Authority (Root CA)  
- ✅ Intermediate Certificate Authority (Intermediate CA)  
- ✅ Domain SSL Certificate (with SAN support)  
- ✅ Properly chained certificate file (`chain.pem`)  
- ✅ Verification of keys and certificate chain  

Perfect for:
- Homelab environments
- Internal networks
- Dev/Test servers
- Kubernetes, Docker, Nginx, Apache, Traefik, etc.
- Learning how PKI and certificate chains work


## 🚀 Features

- Fully automated SSL generation using OpenSSL
- Creates:
  - Root CA
  - Intermediate CA
  - Domain certificate (wildcard supported)
- Adds **Subject Alternative Names (SAN)**:
  - Domain
  - Wildcard domain
  - Optional IP address
- Builds full certificate chain:
  - `domain.crt + intermediateCA.pem + rootCA.pem → chain.pem`
- Verifies:
  - Private key ↔ certificate match
  - Certificate chain validity

---

## 📁 Files Generated

After running the script, you’ll get:

- `myCA.pem`, `myCA.key` → Root CA
- `intermediateCA.pem`, `intermediateCA.key` → Intermediate CA
- `devopsinaction.lab.crt`, `devopsinaction.lab.key` → Domain certificate
- `chain.pem` → Full chain (domain + intermediate + root)

---

## ⚙️ Configuration

Edit these variables at the top of the script:

```bash
MAIN_DOMAIN="devopsinaction.lab"
DOMAIN_IP="192.168.1.10"
DAYS_VALID=3650
CA_PASSWORD=""
ROOT_CN="My Root CA"
INTERMEDIATE_CN="My Intermediate CA"
INTERMEDIATE_CA_NAME="intermediateCA"

COUNTRY="US"
STATE="California"
LOCALITY="Los Angeles"
ORGANIZATION="My Company Inc."
ORG_UNIT="IT Department"
````

You can:

* Change the domain name
* Add/remove IP from SAN
* Set certificate validity
* Customize organization details
* Add a password to protect the Root CA key

---

## 🛠️ How to Use

1. Clone the repo:

```bash
git clone https://github.com/meibraransari/auto-ssl-generator.git
cd auto-ssl-generator
```

2. Make the script executable:

```bash
chmod +x *.sh
```

3. Run it:

```bash
./generate_ssl.sh 
# Support Domain + Windcard Domain

./generate_ssl_all.sh
# ✅ What this version supports
# ✔ Multiple domains via CLI
# ✔ Wildcard-only OR non-wildcard mode
# ✔ Proper SAN handling (browser-correct)
# ✔ One primary domain (CN) + many SANs
# ✔ Optional IP SAN
# ✔ Safe defaults + clear usage
```

4. After successful run, you’ll see:

```bash
chain.pem
myCA.pem
intermediateCA.pem
yourdomain.crt
yourdomain.key
```

## 🔍 Verification

The script automatically:

* Checks modulus of:

  * Root CA key & cert
  * Intermediate CA key & cert
  * Domain key & cert
* Verifies the chain using:

```bash
openssl verify -CAfile myCA.pem -untrusted intermediateCA.pem yourdomain.crt
```

If everything is correct, you’ll see:

```text
yourdomain.crt: OK
```

## 🌐 How to Use in Web Servers

### Nginx / Apache / Traefik

* Certificate file: `chain.pem`
* Private key file: `yourdomain.key`

## 📦 Trust the Root CA in All types of devices (Windows, Linux, Android, iOS, Docker, etc.)

<details>
<summary>Installation Steps for Windows</summary>

```bash
1. Double-click the downloaded certificate file
2. Click "Install Certificate"
3. Select "Local Machine" and click "Next"
4. Choose "Place all certificates in the following store"
5. Click "Browse" and select "Trusted Root Certification Authorities"
6. Click "Next" and then "Finish"
7. Restart your browser
```

</details>


<details>
<summary>Installation Steps for Mac OS</summary>

```bash
1. Double-click the downloaded certificate file
2. Keychain Access will open automatically
3. Add the certificate to the "System" keychain
4. Double-click the imported certificate
5. Expand the "Trust" section
6. Set "When using this certificate" to "Always Trust"
7. Restart your browser
```

</details>


<details>
<summary>Installation Steps for Linux</summary>

```bash
1. Open terminal
2. Copy the certificate to the correct directory:
3. sudo cp ca-certificate.crt /usr/local/share/ca-certificates/
4. Update the certificate store:
5. sudo update-ca-certificates
6. Restart your browser
```

</details>


<details>
<summary>Installation Steps for IOS</summary>

```bash
1. Download the certificate
2. Go to Settings
3. Tap on "Profile Downloaded" near the top
4. Tap "Install" in the top right
5. Enter your device passcode
6. Tap "Install" again to confirm
7. Go to Settings - General - About - Certificate Trust Settings
8. Enable trust for the installed certificate
9. Restart your browser
```

</details>


<details>
<summary>Installation Steps for Android</summary>

```bash
1. Download the certificate
2. Go to Settings - Security
3. Tap "Install from storage" (might vary by device)
4. Find and select the downloaded certificate
5. Enter a name for the certificate
6. Select "VPN and apps" or "CA certificate"
7. Tap OK to confirm installation
8. Restart your browser
```

</details>




<details>
<summary>Installation Steps for Docker Container</summary>

```bash
# Verify the CA certificate file exists locally
ls ca-certificate.crt
# (Optional) Inspect the certificate content to ensure it is correct
cat ca-certificate.crt
# Set the target container name or ID
CONTAINER=my_container_name

# Install the ca-certificates package inside the running container
# Supports both Alpine (apk) and Debian/Ubuntu (apt-get) based images
docker exec -it $CONTAINER sh -c '
  if command -v apk >/dev/null; then
    # Alpine Linux
    apk add --no-cache ca-certificates
  elif command -v apt-get >/dev/null; then
    # Debian / Ubuntu
    apt-get update && apt-get install -y ca-certificates
  fi
'

# Copy the custom CA certificate into the system CA directory inside the container
# The .crt extension is required for update-ca-certificates to detect the file
docker cp ca-certificate.crt \
  $CONTAINER:/usr/local/share/ca-certificates/custom-ca.crt && \
# Update the container’s trusted CA store to include the new certificate
docker exec -it $CONTAINER update-ca-certificates

# -------------------------
# Quick verification section
# -------------------------
# Test an HTTPS endpoint to verify the certificate is trusted
# The -f flag makes curl fail on SSL or HTTP errors
docker exec $CONTAINER curl -f https://your-ssl-endpoint
# Check whether curl is installed in the container (some minimal images may not have it)
docker exec -it $CONTAINER sh -c 'command -v curl || echo "curl not installed"'
# If the container is running as a non-root user, re-run the CA update as root (UID 0)
docker exec -u 0 -it $CONTAINER update-ca-certificates
```
</details>


---
## 📝 License

This guide is provided as-is for educational and professional use.

## 🤝 Contributing
Feel free to suggest improvements or report issues via pull requests or the issues tab.

## 💼 Connect with Me 👇😊

*   🔥 [**YouTube**](https://www.youtube.com/@DevOpsinAction?sub_confirmation=1)
*   ✍️ [**Blog**](https://ibraransari.blogspot.com/)
*   💼 [**LinkedIn**](https://www.linkedin.com/in/ansariibrar/)
*   👨‍💻 [**GitHub**](https://github.com/meibraransari?tab=repositories)
*   💬 [**Telegram**](https://t.me/DevOpsinActionTelegram)
*   🐳 [**Docker Hub**](https://hub.docker.com/u/ibraransaridocker)

### ⭐ If You Found This Helpful...

***Please star the repo and share it! Thanks a lot!*** 🌟
