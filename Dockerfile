FROM ubuntu:22.04
MAINTAINER Lyle Scott, III "lyle@digitalfoo.net"

ENV DEBIAN_FRONTEND noninteractive

USER root

#>> Postfix setup
#>> Setup syslog-ng to echo postfix log data to the screen

RUN apt-get update && \
apt-get -q -y install \
    postfix \
    mailutils \
    libsasl2-2 \
    ca-certificates \
    libsasl2-modules && \
# main.cf
#postconf -e relayhost=[smtp.gmail.com]:587 && \
postconf -e smtpd_banner="\$myhostname ESMTP" && \
postconf -e relayhost=[SMTP.office365.com]:587 && \
postconf -e smtp_sasl_auth_enable=yes && \
postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd && \
postconf -e smtp_sasl_security_options=noanonymous && \
postconf -e smtp_tls_CAfile=/etc/postfix/cacert.pem  && \
postconf -e smtp_use_tls=yes && \
postconf -e soft_bounce=yes && \
postconf -e header_checks=regexp:/etc/postfix/header_checks && \
postconf -e smtp_header_checks=regexp:/etc/postfix/smtp_header_checks && \
apt-get install -q -y \
    syslog-ng \
    syslog-ng-core && \
# system() can't be used since Docker doesn't allow access to /proc/kmsg.
# https://groups.google.com/forum/#!topic/docker-user/446yoB0Vx6w
sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf && \
# https://github.com/LyleScott/docker-postfix-gmail-relay/issues/1
sed -i '/^smtp_tls_CAfile =/d' /etc/postfix/main.cf && \
sed -i 's/^inet_protocols =.*/inet_protocols = ipv4/' /etc/postfix/main.cf && \
apt-get install -q -y \
    supervisor

COPY supervisord.conf /etc/supervisor/
COPY init.sh /opt/init.sh

#>> Cleanup
RUN rm -rf /var/lib/apt/lists/* /tmp/* && \
apt-get autoremove -y && \
apt-get autoclean && \
ln -sf /dev/stdout /var/log/mail.log

EXPOSE 25

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
