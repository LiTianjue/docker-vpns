#!/bin/bash
# Fridolin Pokorny <fpokorny@redhat.com> 2016
# Script for setting up OpenConnect VPN server (ocserv)

# Configuration values
source "${1-/usr/bin/setup_configuration.sh}" || { echo "Configuration failed"; exit 1; }

[ -z ${DISABLE_OCSERV} ] || { xecho "OpenConnect is disabled, exiting setup"; exit 0; }

xecho "OpenConnect Server configuration started..."

[ -f "${OCSERV_DEFAULT_CONF}" ] \
	|| die "Failed to load default ocserv configuration file"

# Make a backup config if needed
[ "${OCSERV_DEFAULT_CONF}" = "${OCSERV_DIR}" ] \
	&& cp "${OCSERV_DEFAULT_CONF}"{,.bac}

xecho "Cleaning up old configuration, if any" \
	&& rm -f "${OCSERV_DIR}/"{ca,server}.{tmpl,crt,key}

[ -d "${OCSERV_DIR}" ] && mkdir -p "${OCSERV_DIR}"

xecho "Generating CA key..."
certtool --generate-privkey --outfile "${OCSERV_DIR}/ca.key" \
	|| die "Failed to create CA key"

cat >"${OCSERV_DIR}/ca.tmpl" <<EOF
cn = "VPN CA"
organization = "test.ocserv"
serial = 1
expiration_days = -1
ca
signing_key
cert_signing_key
crl_signing_key
EOF

xecho "Generating CA certificate..."
certtool --generate-self-signed                   \
	--load-privkey "${OCSERV_DIR}/ca.key"          \
	--template "${OCSERV_DIR}/ca.tmpl"             \
	--outfile "${OCSERV_DIR}/ca.crt"               \
		|| die "Failed to create CA certificate"

xecho "Generating server key..."
certtool --generate-privkey --outfile "${OCSERV_DIR}/server.key" \
		|| die "Failed to create server key"

cat >"${OCSERV_DIR}/server.tmpl" <<EOF
cn = "VPN server"
dns_name = "test.ocserv"
dns_name = "test.ocserv"
organization = "Unknown Company"
expiration_days = -1
signing_key
encryption_key #only if the generated key is an RSA one
tls_www_server
EOF

xecho "Generating server certificate..."
certtool --generate-certificate                        \
	--load-privkey "${OCSERV_DIR}/server.key"           \
	--load-ca-certificate "${OCSERV_DIR}/ca.crt"        \
	--load-ca-privkey "${OCSERV_DIR}/ca.key"            \
	--template "${OCSERV_DIR}/server.tmpl"              \
	--outfile "${OCSERV_DIR}/server.crt"                \
		|| die "Failed to create server certificate"

xecho "Generating ocserv configuration template"
cat > "${OCSERV_CONF}.template" <<EOF
auth = "plain[${OCSERV_DIR}/ocpasswd]"
#use-occtl = true
max-clients = 4
max-same-clients = 2
tcp-port = 443
udp-port = 443
keepalive = 32400
dpd = 240
server-cert = ${OCSERV_DIR}/server.crt
server-key = ${OCSERV_DIR}/server.key
tls-priorities = "NORMAL:%SERVER_PRECEDENCE:%COMPAT"
auth-timeout = 40
rekey-time = 172800
rekey-method = ssl
disconnect-script = /usr/bin/myscript
use-utmp = true
use-dbus = false
pid-file = /var/run/ocserv.pid
socket-file = /var/run/ocserv-socket
run-as-user = nobody
run-as-group = daemon
device = tun-ocserv
default-domain = vpn.test
ipv4-network = ${OCSERV_NETWORK}
ipv4-netmask = 255.255.255.0
ping-leases = false
route = OCSERV_HOST_IP_ADDR/24
EOF

xecho "Creating run script for OpenVPN"
cat >/usr/bin/run_ocserv.sh <<EOF
#!/bin/bash

echo "Creating OpenConnect server configuration from template..."
IP_ADDR=\`eval ${IP_ADDR_CMD}\`
echo "Using IP address \${IP_ADDR}"
sed "s|OCSERV_HOST_IP_ADDR|\${IP_ADDR}|" "${OCSERV_CONF}.template" > "${OCSERV_CONF}"

echo "Adding user '${OCSERV_USER}'; password '${OCSERV_PASSWD}'"
echo "${OCSERV_PASSWD}" | ocpasswd -c "${OCSERV_DIR}/ocpasswd" "${OCSERV_USER}"

echo "To connect to the server, use 'openconnect --no-cert-check \${IP_ADDR} -u ${OCSERV_USER}', \
password is '${OCSERV_PASSWD}'"

exec /usr/bin/time -v ocserv -f -c "${OCSERV_CONF}" >"${OCSERV_LOG}" 2>&1
EOF
chmod +x /usr/bin/run_ocserv.sh

xecho "Configuration of ocserv successfully ended..."
xecho "Use '/usr/bin/run_ocserv.sh' to run the server"

