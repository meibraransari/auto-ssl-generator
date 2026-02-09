#!/bin/bash
set -e
###############################################################################
# SCRIPT:      generate_ssl.sh
# -----------------------------------------------------------------------------
# DESCRIPTION: This script generates Root CA + Intermediate CA + Domain Certificate
#              Properly Chained
# -----------------------------------------------------------------------------
# USAGE:       ./generate_ssl.sh
# -----------------------------------------------------------------------------
# AUTHOR:      Ibrar Ansari
# DATE:        09-02-2026
# -----------------------------------------------------------------------------
# LICENSE:     MIT License (or other license)
###############################################################################

#########################
# Global Variables
#########################
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


#########################
# Main Script
#########################
# Remove existing old certificates.
rm -f myCA.* $INTERMEDIATE_CA_NAME.* $MAIN_DOMAIN.* *.srl *.cnf *.ext chain.pem 2>/dev/null || true

# Print headers
echo "=================================================================="
echo "🚀 Generating SSL Certificates for $MAIN_DOMAIN"
echo "=================================================================="

# =====================================================================
# 1. Root CA
# =====================================================================
echo "🔹 Creating Root CA..."

openssl genrsa -aes256 -passout pass:$CA_PASSWORD -out myCA.key 4096

cat > openssl_root.cnf <<EOF
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
prompt             = no

[ req_distinguished_name ]
C  = $COUNTRY
ST = $STATE
L  = $LOCALITY
O  = $ORGANIZATION
OU = $ORG_UNIT
CN = $ROOT_CN
EOF

openssl req -x509 -new -nodes -key myCA.key -sha256 -days $DAYS_VALID \
-out myCA.pem -config openssl_root.cnf -passin pass:$CA_PASSWORD

echo "✅ Root CA created."

# =====================================================================
# 2. Intermediate CA
# =====================================================================
echo "🔹 Creating Intermediate CA..."

openssl genrsa -out $INTERMEDIATE_CA_NAME.key 4096

cat > openssl_intermediate.cnf <<EOF
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
prompt             = no

[ req_distinguished_name ]
C  = $COUNTRY
ST = $STATE
L  = $LOCALITY
O  = $ORGANIZATION
OU = $ORG_UNIT
CN = $INTERMEDIATE_CN
EOF

openssl req -new -key $INTERMEDIATE_CA_NAME.key -out $INTERMEDIATE_CA_NAME.csr \
-config openssl_intermediate.cnf

cat > $INTERMEDIATE_CA_NAME.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:TRUE,pathlen:0
keyUsage = digitalSignature, cRLSign, keyCertSign
EOF

openssl x509 -req -in $INTERMEDIATE_CA_NAME.csr -CA myCA.pem -CAkey myCA.key -CAcreateserial \
-out $INTERMEDIATE_CA_NAME.pem -days $DAYS_VALID -sha256 -extfile $INTERMEDIATE_CA_NAME.ext \
-passin pass:$CA_PASSWORD

echo "✅ Intermediate CA created."

# =====================================================================
# 3. Domain Certificate
# =====================================================================
echo "🔹 Creating Domain Certificate..."

openssl genrsa -out $MAIN_DOMAIN.key 2048

cat > openssl_domain.cnf <<EOF
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
prompt             = no

[ req_distinguished_name ]
C  = $COUNTRY
ST = $STATE
L  = $LOCALITY
O  = $ORGANIZATION
OU = $ORG_UNIT
CN = *.$MAIN_DOMAIN
EOF

openssl req -new -key $MAIN_DOMAIN.key -out $MAIN_DOMAIN.csr -config openssl_domain.cnf

cat > $MAIN_DOMAIN.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $MAIN_DOMAIN
DNS.2 = *.$MAIN_DOMAIN
EOF

if [ -n "$DOMAIN_IP" ]; then
    echo "IP.1 = $DOMAIN_IP" >> $MAIN_DOMAIN.ext
fi

openssl x509 -req -in $MAIN_DOMAIN.csr -CA $INTERMEDIATE_CA_NAME.pem -CAkey $INTERMEDIATE_CA_NAME.key -CAcreateserial \
-out $MAIN_DOMAIN.crt -days $DAYS_VALID -sha256 -extfile $MAIN_DOMAIN.ext

echo "✅ Domain certificate generated."

# =====================================================================
# 4. Create full certificate chain
# =====================================================================
echo "🔹 Creating full chain file..."
cat $MAIN_DOMAIN.crt $INTERMEDIATE_CA_NAME.pem myCA.pem > chain.pem
echo "✅ Chain created: chain.pem"

# =====================================================================
# 5. Verify SSL 
# =====================================================================

echo "=================================================================="
echo "🚀 Verifying SSL Certificates for $MAIN_DOMAIN"
echo "=================================================================="


echo "Checking Root CA..."
# Properly handle password-protected or unprotected key
if [ -n "$CA_PASSWORD" ]; then
    openssl rsa -noout -modulus -in myCA.key -passin pass:"$CA_PASSWORD" | openssl md5
else
    # Use explicit empty password for AES-encrypted key
    openssl rsa -noout -modulus -in myCA.key -passin pass:"" | openssl md5
fi
openssl x509 -noout -modulus -in myCA.pem | openssl md5
echo

echo "Checking Intermediate CA..."
openssl rsa -noout -modulus -in $INTERMEDIATE_CA_NAME.key | openssl md5
openssl x509 -noout -modulus -in $INTERMEDIATE_CA_NAME.pem | openssl md5
echo

echo "Checking Domain Certificate..."
openssl rsa -noout -modulus -in $MAIN_DOMAIN.key | openssl md5
openssl x509 -noout -modulus -in $MAIN_DOMAIN.crt | openssl md5
echo

echo "Verifying certificate chain..."
openssl verify -CAfile myCA.pem -untrusted $INTERMEDIATE_CA_NAME.pem $MAIN_DOMAIN.crt

# =====================================================================
# 6. Summary
# =====================================================================
echo ""
echo "=================================================================="
echo "🎉 All certificates generated successfully!"
echo ""
echo "Files generated:"
echo "  - Root CA:             myCA.pem, myCA.key"
echo "  - Intermediate CA:     $INTERMEDIATE_CA_NAME.pem, $INTERMEDIATE_CA_NAME.key"
echo "  - Domain Certificate:  $MAIN_DOMAIN.crt, $MAIN_DOMAIN.key"
echo "  - Chain File:          chain.pem"
echo ""
echo "👉 Next steps:"
echo "  1. Import 'myCA.pem' as trusted root in OS/browser or container."
echo "  2. Use 'chain.pem' for your web server (includes domain + intermediate + root)."
echo "=================================================================="


