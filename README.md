# Setup wireguard vpn server on Debian 12
```bash
apt update
apt install wireguard iptables qrencode -y

# generate server private and publickey
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
chmod 600 /etc/wireguard/{server_private.key,server_public.key}

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.0.1/24
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 51820
PrivateKey = `cat /etc/wireguard/server_private.key`
EOF

# Set client number
CLIENT_NUM=2

# Set the client's IP address based on the client number
CLIENT_IP="10.0.0.$CLIENT_NUM"

# generate client1 private and public key
wg genkey | tee /etc/wireguard/client${CLIENT_NUM}_private.key | wg pubkey > /etc/wireguard/client${CLIENT_NUM}_public.key

cat >> /etc/wireguard/wg0.conf <<EOF

# Client ${CLIENT_NUM}
[Peer]
PublicKey = `cat /etc/wireguard/client${CLIENT_NUM}_public.key`
AllowedIPs = $CLIENT_IP/32
EOF

# This is client's config. 
# We don't need one server, but just using it here for clear code generation and easy import.
cat > /etc/wireguard/client${CLIENT_NUM}.conf <<EOF
[Interface]
PrivateKey = `cat /etc/wireguard/client${CLIENT_NUM}_private.key`
Address = $CLIENT_IP/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = `cat /etc/wireguard/server_public.key`
AllowedIPs = 0.0.0.0/0
Endpoint = `curl checkip.amazonaws.com`:51820
PersistentKeepalive = 25
EOF

# show QR code to for client settings
sudo qrencode -t ansiutf8 < /etc/wireguard/client${CLIENT_NUM}.conf

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

sudo wg set wg0 peer `cat /etc/wireguard/client${CLIENT_NUM}_public.key` allowed-ips $CLIENT_IP/32

echo "Created configuration for client ${CLIENT_NUM} with IP ${CLIENT_IP}/32"

# restart after making changes
systemctl restart wg-quick@wg0

# check status
systemctl status wg-quick@wg0

# ufw allow 51820/udp

echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Check iptables FORAWRD chain NO!! first rule -P FORWARD DROP
sudo iptables -S
# if have DROP rule - Very important to allow FORAWRD if blocked
sudo iptables -P FORWARD ACCEPT
# and save it so that after reboot it will work:
sudo apt install -y iptables-persistent
sudo sh -c "iptables-save > /etc/iptables/rules.v4"

# just to know: Lists all chains in the filter table with packet and byte counters.
iptables -L -n -v
```
