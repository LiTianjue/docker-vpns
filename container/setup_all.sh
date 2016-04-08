#!/bin/bash
# Fridolin Pokorny <fpokorny@redhat.com>
# Script for setting up ocserv, OpenVPN and Libreswan

VPNS_SETUP_LOG="${SETUP_LOG-/var/log/vpns}"

echo "Requesting OpenConnect server (ocserv) to be set up"         \
	&& /usr/bin/setup_ocserv.sh 2>&1 | tee -a "${VPNS_SETUP_LOG}" || exit 1

echo "Requesting OpenVPN to be set up"                             \
	&& /usr/bin/setup_openvpn.sh 2>&1 | tee -a "${VPNS_SETUP_LOG}" || exit 1

echo "Requesting Libreswan to be set up"                           \
	&& /usr/bin/setup_libreswan.sh 2>&1 | tee -a "${VPNS_SETUP_LOG}" || exit 1

nc -l -o /dev/null &

iperf -s &
