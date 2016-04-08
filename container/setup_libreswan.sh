#!/bin/bash
# Fridolin Pokorny <fpokorny@redhat.com> 2016
# Script for setting up IPSec VPN (Libreswan)

# Configuration values
source "${1-/usr/bin/setup_configuration.sh}" || { echo "Configuration failed"; exit 1; }

[ -z ${DISABLE_LIBRESWAN} ] || { xecho "Libreswan is disabled, exiting setup"; exit 0; }

xecho "Libreswan configuration started..."

xecho "Creating configuraton file template"
cat >"${LIBRESWAN_CONF}.template" <<EOF
version 2.0
config setup
        dumpdir=/var/run/pluto/
        nat_traversal=yes
        virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!192.168.42.0/24
        oe=off
        #protostack=netkey
        plutodebug=all
        klipsdebug=all
        #interfaces=%defaultroute
        #uniqueids=no

conn vpn
        connaddrfamily=ipv4
        type=transport
        authby=secret
        left=LIBRESWAN_HOST_IP_ADDR
        leftid=@vpn
        right=%any
        aggrmode=yes
        auto=add
        pfs=no
        sareftrack=no
        ikev2=no
        remote_peer_type=cisco
        rekey=no
        nat-keepalive=no
        ike-frag=no
        forceencaps=yes
        leftxauthserver=yes
        ike=aes256-sha1,aes128-sha1,3des-sha1
        phase2alg=aes256-sha1,aes128-sha1,3des-sha1

        modecfgpull=yes
        leftmodecfgserver=yes
        rightmodecfgclient=yes

        leftnexthop=LIBRESWAN_HOST_IP_ADDR
        leftprotoport=udp/1701
EOF

xecho "Creating Libreswan secrets file '${LIBRESWAN_SECRET_FILE}'..."
cat >"${LIBRESWAN_SECRET_FILE}.template" <<EOF
LIBRESWAN_HOST_IP_ADDR  %any  : PSK "${LIBRESWAN_SECRET}"
@${LIBRESWAN_USER} : XAUTH "${LIBRESWAN_PASSWD}"
EOF

xecho "Creating run script for Libreswan"
cat >/usr/bin/run_libreswan.sh <<EOF
#!/bin/bash

echo "Creating Libreswan configuration from template..."
IP_ADDR=\`eval ${IP_ADDR_CMD}\`
echo "Using IP address \${IP_ADDR}"
sed "s|LIBRESWAN_HOST_IP_ADDR|\${IP_ADDR}|" "${LIBRESWAN_CONF}.template" > "${LIBRESWAN_CONF}"
sed "s|LIBRESWAN_HOST_IP_ADDR|\${IP_ADDR}|" "${LIBRESWAN_SECRET_FILE}.template" > "${LIBRESWAN_SECRET_FILE}"

echo "To connect to Libreswan, use run:\
'vpnc --gateway \${IP_ADDR} --id vpn --auth-mode psk --local-port 0 --username ${LIBRESWAN_USER}'"
echo "Using secret '${LIBRESWAN_SECRET}' and password '${LIBRESWAN_PASSWD}'"
echo "Or place following lines to you /etc/vpnc/default.conf file:\n\
IPSec gateway \${IP_ADDR}
IPSec ID vpn
IPSec secret ${LIBRESWAN_SECRET}
Xauth username ${LIBRESWAN_USER}
Xauth password ${LIBRESWAN_PASSWD}
Local Port 0
IKE Authmode psk
"

htpasswd -c -d -b "${LIBRESWAN_PASS_FILE}.template" "${LIBRESWAN_USER}" "${LIBRESWAN_PASSWD}"
echo "vpn" | paste -d: "${LIBRESWAN_PASS_FILE}.template" - > "${LIBRESWAN_PASS_FILE}"

/usr/libexec/ipsec/addconn --config ${LIBRESWAN_CONF} --checkconfig
/usr/libexec/ipsec/_stackmanager start
/usr/sbin/ipsec --checknss
exec /usr/bin/time -v /usr/libexec/ipsec/pluto --config ${LIBRESWAN_CONF} --nofork --logfile "${LIBRESWAN_LOG}"
EOF
chmod +x /usr/bin/run_libreswan.sh

xecho "Configuration of Libreswan successfully ended..."
xecho "To run Libreswan, use '/usr/bin/run_libreswan.sh'"

