#!/bin/bash

ADAPTER="${NET_ADAPTER:=eth0}"
source ./functions.sh

mkdir -p /dev/net

if [ ! -c /dev/net/tun ]; then
    echo "$(datef) Creating tun/tap device."
    mknod /dev/net/tun c 10 200
fi

# Allow UDP traffic on port 1194.
iptables -A INPUT -i $ADAPTER -p udp -m state --state NEW,ESTABLISHED --dport 1194 -j ACCEPT
iptables -A OUTPUT -o $ADAPTER -p udp -m state --state ESTABLISHED --sport 1194 -j ACCEPT

# Allow traffic on the TUN interface.
iptables -A INPUT -i tun0 -j ACCEPT
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A OUTPUT -o tun0 -j ACCEPT

# Allow forwarding traffic only from the VPN.
iptables -A FORWARD -i tun0 -o $ADAPTER -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $ADAPTER -j MASQUERADE

cd "$APP_PERSIST_DIR"

LOCKFILE=.gen

# Regenerate certs only on the first start 
if [ ! -f $LOCKFILE ]; then
    IS_INITIAL="1"
    cp -R ${APP_PERSIST_DIR}.template/* ${APP_PERSIST_DIR}/
    # If existing CA is already in place, we need to clean it up
    easyrsa --batch init-pki
    easyrsa --batch build-ca nopass 
    # CA creation complete and you may now import and sign cert requests.
    # Your new CA certificate file for publishing is at:
    # /opt/Dockovpn_data/pki/ca.crt

    easyrsa --batch gen-req MyReq nopass 
    # Keypair and certificate request completed. Your files are:
    # req: /opt/Dockovpn_data/pki/reqs/MyReq.req
    # key: /opt/Dockovpn_data/pki/private/MyReq.key

    easyrsa --batch sign-req server MyReq 
    # Certificate created at: /opt/Dockovpn_data/pki/issued/MyReq.crt

    openvpn --genkey secret ta.key << EOF4
yes
EOF4
    

    touch $LOCKFILE
fi

# Regenereate CRL on each startup, with a 10 years expiry
EASYRSA_CRL_DAYS=3650 easyrsa gen-crl

# We need to check if a renew of the server certificate is required
# The server certificate is valid for 14 days, or custom variable CERTAGE
[ -z "$CERTAGE"] && CERTAGE=14
echo "Checking if the server certificate is still valid"
openssl x509 -in pki/issued/MyReq.crt -checkend $(( ${CERTAGE} * 86400 )) -noout
if [ $? -eq 0 ]; then
    echo "Server Certificate is still valid"
else
    echo "Server Certificate is expired, regenerating"
    mv -f pki/issued/MyReq.crt pki/issued/MyReq.crt.old
    # Renew the certificate
    easyrsa --batch sign-req server MyReq
fi

# Copy initial configuration and scripts if /etc/openvpn is empty
# Allows /etc/openvpn to be mapped to persistent volume
if [[ ! -f /etc/openvpn/server.conf ]]; then
    cp /etc/openvpn.template/* /etc/openvpn/
fi

# Copy server keys and certificates
cp pki/dh.pem pki/ca.crt pki/issued/MyReq.crt pki/private/MyReq.key pki/crl.pem ta.key /etc/openvpn

cd "$APP_INSTALL_PATH"

# Print app version
$APP_INSTALL_PATH/version.sh

# Need to feed key password
openvpn --config /etc/openvpn/server.conf &

if [[ -n $IS_INITIAL ]]; then
    # By some strange reason we need to do echo command to get to the next command
    echo " "

    # Generate client config
    ./genclient.sh $@
fi

tail -f /dev/null
