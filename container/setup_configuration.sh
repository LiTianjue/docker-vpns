#!/bin/bash
# Fridolin Pokorny <fpokorny@redhat.com> 2016
# Script holding setup configuration

die() { echo "!!! $@" 1>&2 ; exit 1; }
xecho() { echo -e ">>> $@"; }

# TODO: DEBUG options

# Uncomment if you want to disable some
#DISABLE_OCSERV=1
#DISABLE_OPENVPN=1
#DISABLE_LIBRESWAN=1

# OpenConnect Server
OCSERV_DIR="${OCSERV_DIR-/etc/ocserv}"
OCSERV_CONF="${OCSERV_CONF-${OCSERV_DIR}/my_ocserv.conf}"
OCSERV_DEFAULT_CONF="${OCSERV_DEFAULT_CONF-${OCSERV_DIR}/ocserv.conf}"
OCSERV_USER="${OCSERV_USER-user}"
OCSERV_PASSWD="${OCSERV_PASSWD-pass}"
OCSERV_NETWORK="${OCSERV_NETWORK-192.168.202.0}"
OCSERV_LOG="/var/log/ocserv.log"
#OCSERV_DEBUG=1

# OpenVPN
OPENVPN_DIR="${OPENVPN_DIR-/etc/openvpn}"
OPENVPN_SERVER_CONF="${OPENVPN_CONF-${OPENVPN_DIR}/server.conf}"
OPENVPN_CLIENT_CONF="${OPENVPN_CONF-${OPENVPN_DIR}/client.conf}"
OPENVPN_USER="${OPENVPN_USER-user}"
OPENVPN_PASSWD="${OPENVPN_PASSWD-pass}"
OPENVPN_NETWORK="${OPENVPN__NETWORK-192.168.255.0 255.255.255.0}"
OPENVPN_LOG="/var/log/openvpn.log"
#OPENVPN_DEBUG=1

# LibreSwan
LIBRESWAN_CONF="${LIBRESWAN_CONF-/etc/ipsec.conf}"
LIBRESWAN_PASS_FILE="${LIBRESWAN_PASS_FILE-/etc/ipsec.d/passwd}"
LIBRESWAN_SECRET_FILE="${LIBRESWAN_SECRET_FILE-/etc/ipsec.secrets}"
LIBRESWAN_USER="${LIBRESWAN_USER-user}"
LIBRESWAN_PASSWD="${LIBRESWAN_PASSWD-pass}"
LIBRESWAN_SECRET="${LIBRESWAN_SECRET-secret}"
LIBRESWAN_LOG="/var/log/ipsec.log"
#LIBRESWAN_DEBUG=1

NETWORK_DEVICE="eth0"
IP_ADDR_CMD="ip -4 addr list ${NETWORK_DEVICE} | grep inet | cut -d' ' -f6 | cut -d\/ -f1"

