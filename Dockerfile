# Docker file for image with configured VPN clients
# Fridolin Pokorny <fpokorny@redhat.com>

FROM fedora:23
MAINTAINER Fridolin Pokorny <fpokorny@redhat.com>

# 443   ocserv
# 1194  OpenVPN
# 4500  IPSec
# 5000  nuttcp server
# 5001  nuttcp client and iperf
EXPOSE 443 1194 4500 5000 5001

ENV PACKAGES='ocserv libreswan openvpn \
net-tools nuttcp iperf gnutls-utils iputils policycoreutils \
xl2tpd kernel-modules-extra httpd-tools vim time nmap-ncat'

RUN dnf install -y ${PACKAGES}

COPY container/setup_openvpn.sh           /usr/bin/
COPY container/setup_ocserv.sh            /usr/bin/
COPY container/setup_libreswan.sh         /usr/bin/
COPY container/setup_configuration.sh     /usr/bin/

COPY container/setup_all.sh               /usr/bin/
COPY container/entrypoint.sh              /usr/bin/

RUN /usr/bin/setup_all.sh

ENTRYPOINT ["/usr/bin/entrypoint.sh"]

