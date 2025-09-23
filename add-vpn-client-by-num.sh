#!/bin/bash
# run it like: ./add-vpn-client.sh 2 for client 1, ./add-vpn-client.sh 3 for client 2, etc.
# Start from client 2, because client number = ip address

# Check if client number is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <client_number>"
  exit 1
fi

# Set client number from first argument
CLIENT_NUM=$1

# Check if CLIENT_NUM is a digit and in range 2-254
if ! [[ "$CLIENT_NUM" =~ ^[0-9]+$ ]]; then
  echo "Error: CLIENT_NUM must be a number." >&2
  exit 1
elif [ "$CLIENT_NUM" -le 1 ] || [ "$CLIENT_NUM" -ge 255 ]; then
  echo "Error: CLIENT_NUM must be greater than 1 and less than 255." >&2
  exit 1
fi

# Set the client's IP address based on the client number
#CLIENT_IP="10.0.0.$((CLIENT_NUM + 1))"
CLIENT_IP="10.0.0.$CLIENT_NUM"

if [ -f "/etc/wireguard/client${CLIENT_NUM}_private.key" ]; then
    ls -latr /etc/wireguard/
    echo "Client number $CLIENT_NUM exists. Try another."
    exit 1
fi

# generate client1 private and public key
wg genkey | tee /etc/wireguard/client${CLIENT_NUM}_private.key | wg pubkey > /etc/wireguard/client${CLIENT_NUM}_public.key

# Add client to server config
cat >> /etc/wireguard/wg0.conf <<EOF

[Peer]
PublicKey = `cat /etc/wireguard/client${CLIENT_NUM}_public.key`
AllowedIPs = ${CLIENT_IP}/32
EOF

# Generate client config
cat > /etc/wireguard/client${CLIENT_NUM}.conf <<EOF
[Interface]
PrivateKey = `cat /etc/wireguard/client${CLIENT_NUM}_private.key`
Address = ${CLIENT_IP}/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = `cat /etc/wireguard/server_public.key`
AllowedIPs = 0.0.0.0/0
Endpoint = `curl -s checkip.amazonaws.com`:51820
PersistentKeepalive = 25
EOF

systemctl reload wg-quick@wg0

echo "Created configuration for client ${CLIENT_NUM} with IP ${CLIENT_IP}/32 Use config:"
echo "cat /etc/wireguard/client${CLIENT_NUM}.conf"
echo ""
cat /etc/wireguard/client${CLIENT_NUM}.conf
# show QR code to for client settings
sudo qrencode -t ansiutf8 < /etc/wireguard/client${CLIENT_NUM}.conf
