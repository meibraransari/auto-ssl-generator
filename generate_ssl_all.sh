#!/bin/bash
set -e
###############################################################################
# SCRIPT:      generate_ssl_all.sh
# -----------------------------------------------------------------------------
# DESCRIPTION: This script generates Root CA + Intermediate CA + Domain Certificate
#              Properly Chained
# -----------------------------------------------------------------------------
# USAGE:       ./generate_ssl_all.sh
# -----------------------------------------------------------------------------
# AUTHOR:      Ibrar Ansari
# DATE:        09-02-2026
# -----------------------------------------------------------------------------
# LICENSE:     MIT License (or other license)
###############################################################################
# ✅ What this version supports
# ✔ Multiple domains via CLI
# ✔ Wildcard-only OR non-wildcard mode
# ✔ Proper SAN handling (browser-correct)
# ✔ One primary domain (CN) + many SANs
# ✔ Optional IP SAN
# ✔ Safe defaults + clear usage
##########################################

### Defaults
DAYS_VALID=3650
CA_PASSWORD=""
INTERMEDIATE_CA_NAME="intermediateCA"

COUNTRY="US"
STATE="California"
LOCALITY="Los Angeles"
ORGANIZATION="My Company Inc."
ORG_UNIT="IT Department"

ROOT_CN="My Root CA"
INTERMEDIATE_CN="My Intermediate CA"

WILDCARD=false
DOMAIN_IP=""
DOMAINS=""

### -------------------------
### Argument parsing
### -------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domains)
      DOMAINS="$2"
      shift 2
      ;;
    --wildcard)
      WILDCARD=true
      shift
      ;;
    --no-wildcard)
      WILDCARD=false
      shift
      ;;
    --ip)
      DOMAIN_IP="$2"
      shift 2
      ;;
    --days)
      DAYS_VALID="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$DOMAINS" ]]; then
  echo "Script made by: @DevOpsInAction - Ibrar Ansari"
  echo "Usage: ./generate_ssl_all.sh --domains <domains>"
  echo "Example:"
  echo "./generate_ssl_all.sh --domains devopsinaction.lab"
  echo "./generate_ssl_all.sh --domains devopsinaction.lab --wildcard"
  echo "./generate_ssl_all.sh --domains api.lab.local,admin.lab.local"
  echo "./generate_ssl_all.sh --domains example.com,example.internal --wildcard --ip 10.0.0.5"
  exit 1
fi

IFS=',' read -ra DOMAIN_ARRAY <<< "$DOMAINS"
PRIMARY_DOMAIN="${DOMAIN_ARRAY[0]}"

echo "=================================================================="
echo "🚀 Generating SSL Certificates"
echo "   Primary Domain: $PRIMARY_DOMAIN"
echo "   Domains:        $DOMAINS"
echo "   Wildcard:       $WILDCARD"
echo "=================================================================="

### Cleanup
rm -f myCA.* $INTERMEDIATE_CA_NAME.* "$PRIMARY_DOMAIN".* *.srl *.cnf *.ext chain.pem 2>/dev/null || true

# =====================================================================
# 1. Root CA
# =====================================================================
openssl genrsa -aes256 -passout pass:$CA_PASSWORD -out myCA.key 4096

cat > openssl_root.cnf <<EOF
[ req ]
distinguished_name = dn
prompt = no

[ dn ]
C=$COUNTRY
ST=$STATE
L=$LOCALITY
O=$ORGANIZATION
OU=$ORG_UNIT
CN=$ROOT_CN
EOF

openssl req -x509 -new -key myCA.key -sha256 -days $DAYS_VALID \
  -out myCA.pem -config openssl_root.cnf -passin pass:$CA_PASSWORD

# =====================================================================
# 2. Intermediate CA
# =====================================================================
openssl genrsa -out $INTERMEDIATE_CA_NAME.key 4096

cat > openssl_intermediate.cnf <<EOF
[ req ]
distinguished_name = dn
prompt = no

[ dn ]
C=$COUNTRY
ST=$STATE
L=$LOCALITY
O=$ORGANIZATION
OU=$ORG_UNIT
CN=$INTERMEDIATE_CN
EOF

openssl req -new -key $INTERMEDIATE_CA_NAME.key \
  -out $INTERMEDIATE_CA_NAME.csr -config openssl_intermediate.cnf

cat > $INTERMEDIATE_CA_NAME.ext <<EOF
basicConstraints=CA:TRUE,pathlen:0
keyUsage=keyCertSign,cRLSign
EOF

openssl x509 -req -in $INTERMEDIATE_CA_NAME.csr \
  -CA myCA.pem -CAkey myCA.key -CAcreateserial \
  -out $INTERMEDIATE_CA_NAME.pem -days $DAYS_VALID \
  -sha256 -extfile $INTERMEDIATE_CA_NAME.ext \
  -passin pass:$CA_PASSWORD

# =====================================================================
# 3. Domain Certificate
# =====================================================================
openssl genrsa -out "$PRIMARY_DOMAIN.key" 2048

cat > openssl_domain.cnf <<EOF
[ req ]
distinguished_name = dn
prompt = no

[ dn ]
C=$COUNTRY
ST=$STATE
L=$LOCALITY
O=$ORGANIZATION
OU=$ORG_UNIT
CN=$PRIMARY_DOMAIN
EOF

openssl req -new -key "$PRIMARY_DOMAIN.key" \
  -out "$PRIMARY_DOMAIN.csr" -config openssl_domain.cnf

cat > "$PRIMARY_DOMAIN.ext" <<EOF
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names

[alt_names]
EOF

i=1
for domain in "${DOMAIN_ARRAY[@]}"; do
  echo "DNS.$i = $domain" >> "$PRIMARY_DOMAIN.ext"
  i=$((i+1))

  if $WILDCARD; then
    echo "DNS.$i = *.$domain" >> "$PRIMARY_DOMAIN.ext"
    i=$((i+1))
  fi
done

if [[ -n "$DOMAIN_IP" ]]; then
  echo "IP.1 = $DOMAIN_IP" >> "$PRIMARY_DOMAIN.ext"
fi

openssl x509 -req -in "$PRIMARY_DOMAIN.csr" \
  -CA $INTERMEDIATE_CA_NAME.pem -CAkey $INTERMEDIATE_CA_NAME.key \
  -CAcreateserial -out "$PRIMARY_DOMAIN.crt" \
  -days $DAYS_VALID -sha256 -extfile "$PRIMARY_DOMAIN.ext"

# =====================================================================
# 4. Chain
# =====================================================================
cat "$PRIMARY_DOMAIN.crt" $INTERMEDIATE_CA_NAME.pem myCA.pem > chain.pem

# =====================================================================
# 5. Verify
# =====================================================================
openssl verify -CAfile myCA.pem \
  -untrusted $INTERMEDIATE_CA_NAME.pem "$PRIMARY_DOMAIN.crt"

echo "=================================================================="
echo "🎉 DONE"
echo "Primary cert : $PRIMARY_DOMAIN.crt"
echo "Private key  : $PRIMARY_DOMAIN.key"
echo "Chain        : chain.pem"
echo "=================================================================="
