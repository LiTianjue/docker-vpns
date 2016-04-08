#!/bin/bash
# Fridolin Pokorny <fpokorny@redhat.com> 2016
# Script for setting Docker image with VPNs and running VPN clients from host

# Configuration values
CONFIG="${1-./container/setup_configuration.sh}"
source "${CONFIG}" || { echo "Sourcing configuration failed"; exit 1; }

# Redefine, so we can see who is host (only this script)
# TODO: better way?
# http://stackoverflow.com/questions/23513045/how-to-check-if-a-process-is-running-inside-docker-container
xecho() { echo -e "<<< $@"; }

DOCKER_LOGFILE="${DOCKER_LOGFILE-./dockerbuild.log}"
OPENVPN_HOST_CLIENT_CONF="${OPENVPN_HOST_CLIENT_CONF-./openvpn-client.conf}"

[ -z ${DISABLE_OCSERV} ] && {
	which openconnect >/dev/null || \
		die "Please install OpenConnect client using 'dnf install openconnect'"
}

[ -z ${DISABLE_OPENVPN} ] && {
	which openvpn >/dev/null || \
		die "Please install OpenVPN using 'dnf install openvpn'"
}

[ -z ${DISABLE_LIBRESWAN} ] && {
	which vpnc >/dev/null || \
		die "Please install vpnc using 'dnf install vpnc'"
}

xecho "Configuration:" && (
	set -x
	source "${CONFIG}"
)

xecho "Building Docker image..."
LC_ALL=C docker build -t vpns . 2>&1 | tee -a "${DOCKER_LOGFILE}"
[ ${PIPESTATUS[0]} -ne 0 ] && die "Failed to build Dcoker image"

DOCKER_IMAGE=`tail -n1 dockerbuild.log | cut -d' ' -f3`
xecho "Spawning docker container '${DOCKER_IMAGE}'..." | tee -a "${DOCKER_LOGFILE}"
docker run -d --privileged \
	-p 443/udp      \
	-p 500/udp      \
	-p 1194/udp     \
	-p 4500/udp     \
	-p 5000/udp     \
	-p 5001/udp "${DOCKER_IMAGE}" 2>&1 | tee -a "${DOCKER_LOGFILE}"

[ ${PIPESTATUS[0]} -ne 0 ] && die "Failed to build Docker image"

DOCKER_CONTAINER=`tail -n1 ${DOCKER_LOGFILE}`
xecho "Using Docker container '${DOCKER_CONTAINER}'" | tee -a "${DOCKER_LOGFILE}"

CONTAINER_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' "${DOCKER_CONTAINER}"`
xecho "IP of container ${DOCKER_CONTAINER} is ${CONTAINER_IP}" | tee -a "${DOCKER_LOGFILE}"

# Wait some time for servers to become ready
sleep 5s
xecho "To stop container, run 'docker stop ${DOCKER_CONTAINER}'"
xecho "To attach to container, run 'docker exec -ti ${DOCKER_CONTAINER} bash'"
xecho "To clear image, run 'docker rmi -f ${DOCKER_IMAGE}'"

#### Running clients
xecho "Running clients on host..." | tee -a "${DOCKER_LOGFILE}"

[ -z ${DISABLE_OPENVPN} ] && {
	xecho "Copying OpenVPN client configuration..."
	docker cp "${DOCKER_CONTAINER}:${OPENVPN_CLIENT_CONF}" "${OPENVPN_HOST_CLIENT_CONF}" \
		|| die "Failed to copy OpenVPN client configuration to ${OPENVPN_HOST_CLIENT_CONF}"
	xecho "Running OpenVPN with client configuration '${OPENVPN_HOST_CLIENT_CONF}...'"
	openvpn "${OPENVPN_HOST_CLIENT_CONF}" &
	OPENVPN_PID="$!"
}

[ -z ${DISABLE_OCSERV} ] && {
	xecho "Running OpenConncet client..."
	echo "${OCSERV_PASSWD}" | openconnect --no-cert-check "${CONTAINER_IP}" -u user &
	OPENCONNECT_PID="$!"
}

[ -z ${DISABLE_LIBRESWAN} ] && {
	xecho "Running vpnc client for IPSec (Libreswan)..."
	set -x
	vpnc --gateway "${CONTAINER_IP}" --id vpn --auth-mode psk --local-port 0 --username "${LIBRESWAN_USER}" &
	LIBRESWAN_PID="$!"
}

#[ -z ${DISABLE_OPENVPN} ]    &&  wait "${OPENVPN_PID}"
#[ -z ${DISABLE_OCSERV} ]     &&  wait "${OCSERV_PID}"
#[ -z ${DISABLE_LIBRESWAN} ]  &&  wait "${LIBRESWAN_PID}"

xecho "To stop container, run 'docker stop ${DOCKER_CONTAINER}'"
xecho "To attach to container, run 'docker exec -ti ${DOCKER_CONTAINER} bash'"
xecho "To clear image, run 'docker rmi -f ${DOCKER_IMAGE}'"

