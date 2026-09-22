#!/bin/bash
set -e

IP=$(hostname -I | awk '{print $1}')
echo "=== GENERATING SSL SAN IP CERTIFICATE FOR ${IP} ==="

mkdir -p /etc/x-ui /root/cert/ip

# OpenSSL config with SAN IP
cat << EOF > /tmp/openssl_ip.cnf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${IP}

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = ${IP}
EOF

# Generate Private Key and Certificate for 10 years (3650 days)
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/x-ui/server.key \
    -out /etc/x-ui/server.crt \
    -config /tmp/openssl_ip.cnf -extensions v3_req

chmod 600 /etc/x-ui/server.key
chmod 644 /etc/x-ui/server.crt

# Copy to /root/cert/ip/ as fullchain and privkey
cp /etc/x-ui/server.crt /root/cert/ip/fullchain.pem
cp /etc/x-ui/server.key /root/cert/ip/privkey.pem
chmod 600 /root/cert/ip/privkey.pem
chmod 644 /root/cert/ip/fullchain.pem

# Update database settings to use HTTPS certificates
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/etc/x-ui/server.crt' WHERE key = 'webCertFile';"
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/etc/x-ui/server.key' WHERE key = 'webKeyFile';"

systemctl daemon-reload
systemctl restart x-ui
sleep 2

echo "=== CERTIFICATE DETAILS ==="
openssl x509 -in /etc/x-ui/server.crt -subject -dates -noout
openssl x509 -in /etc/x-ui/server.crt -text -noout | grep -A 1 "Subject Alternative Name" || true

echo "=== HTTPS TEST ==="
PORT=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key = 'webPort';")
PATH_URL=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key = 'webBasePath';")
echo "Testing: https://${IP}:${PORT}${PATH_URL}"
curl -k -i -s "https://127.0.0.1:${PORT}${PATH_URL}" | head -n 15
