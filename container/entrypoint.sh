#!/bin/bash
# Fridolin Pokorny <fpokorny@redhat.com> 2016
# Docker entrypoint script

# Configuration values
source "${1-/usr/bin/setup_configuration.sh}" || { echo "Sourcing configuration failed"; exit 1; }

[ -z ${DISABLE_OPENVPN} ]    ||  xecho "OpenVPN will be skipped according to configuration..."
[ -z ${DISABLE_OCSERV} ]     ||  xecho "OpenConect will be skipped according to configuration..."
[ -z ${DISABLE_LIBRESWAN} ]  ||  xecho "Libreswan will be skipped according to configuration..."

[ -z ${DISABLE_OPENVPN} ]    && /usr/bin/run_openvpn.sh &
[ -z ${DISABLE_OCSERV} ]     && /usr/bin/run_ocserv.sh &
[ -z ${DISABLE_LIBRESWAN} ]  && /usr/bin/run_libreswan.sh &

exec sleep infinity

