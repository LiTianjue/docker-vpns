#!/bin/bash
# Fridolin Pokorny <fpokorny@redhat.com> 2016
# Script for setting up OpenVPN server

# Configuration values
source "${1-/usr/bin/setup_configuration.sh}" || { echo "Configuration failed"; exit 1; }

[ -z ${DISABLE_OPENVPN} ] || { xecho "OpenVPN is disabled, exiting setup"; exit 0; }

xecho "OpenVPN configuration started..."

xecho "Generating DH parameters..."
openssl dhparam -out "${OPENVPN_DIR}/dh.pem" 1024 \
	|| die "Failed to generatie DH parameters"

xecho "Generating RSA key..."
openssl genrsa -out "${OPENVPN_DIR}/key.pem" 2048 \
	|| die "Failed to generate RSA key"
chmod 600 "${OPENVPN_DIR}/key.pem"

xecho "Generating key PEM file..."
openssl req -new -key "${OPENVPN_DIR}/key.pem"         \
	-out "${OPENVPN_DIR}/csr.pem" -subj '/CN=OpenVPN/'  \
		|| die "Failed to generate key PEM file"

xecho "Generating cert PEM file..."
openssl x509 -req -days 666           \
	-in "${OPENVPN_DIR}/csr.pem"       \
	-signkey "${OPENVPN_DIR}/key.pem"  \
	-out "${OPENVPN_DIR}/cert.pem"     \
		|| die "Failed to generate cert PEM file"

xecho "Creating OpenVPN server configuration..."
cat >"${OPENVPN_SERVER_CONF}" <<EOF
server ${OPENVPN_NETWORK}
verb 3
duplicate-cn
key ${OPENVPN_DIR}/key.pem
ca ${OPENVPN_DIR}/cert.pem
cert ${OPENVPN_DIR}/cert.pem
dh ${OPENVPN_DIR}/dh.pem
keepalive 10 60
persist-key
persist-tun
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

proto udp
port 1194
dev tun-openvpn
EOF

xecho "Creating OpenVPN client configuration template..."
cat >"${OPENVPN_CLIENT_CONF}.template" <<EOF
client
nobind
dev tun

<key>
`cat ${OPENVPN_DIR}/key.pem`
</key>
<cert>
`cat ${OPENVPN_DIR}/cert.pem`
</cert>
<ca>
`cat ${OPENVPN_DIR}/cert.pem`
</ca>
<dh>
`cat ${OPENVPN_DIR}/dh.pem`
</dh>

<connection>
remote OPENVPN_HOST_IP_ADDR 1194 udp
</connection>
EOF

xecho "Creating run script for OpenVPN"
cat >/usr/bin/run_openvpn.sh <<EOF
#!/bin/bash

echo "Creating OpenVPN client configuration from template..."
IP_ADDR=\`eval ${IP_ADDR_CMD}\`
echo "Using IP address \${IP_ADDR}"
sed "s|OPENVPN_HOST_IP_ADDR|\${IP_ADDR}|" "${OPENVPN_CLIENT_CONF}.template" > "${OPENVPN_CLIENT_CONF}"

echo "To connect to server, use '${OPENVPN_CLIENT_CONF}', located on the server"
echo "You can use 'docker cp <containerId>:/etc/openvpn/client.conf .' to get it"
exec /usr/bin/time -v openvpn ${OPENVPN_SERVER_CONF} >"${OPENVPN_LOG}" 2>&1
EOF
chmod +x /usr/bin/run_openvpn.sh

xecho "Configuration of OpenVPN successfully ended..."
xecho "To run OpenVPN server, use '/usr/bin/run_openvpn.sh'"
xecho "To connect to ocserv, use prepared client config situated in '${OPENVPN_CLIENT_CONF}'"

