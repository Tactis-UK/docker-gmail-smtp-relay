#!/bin/sh

# Set timezone
if [ ! -z "${SYSTEM_TIMEZONE}" ]; then
    echo "configuring system timezone"
    echo "${SYSTEM_TIMEZONE}" > /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata
fi

# Set mynetworks for postfix relay
if [ ! -z "${MYNETWORKS}" ]; then
    echo "setting mynetworks = ${MYNETWORKS}"
    postconf -e mynetworks="${MYNETWORKS}"
fi

# General the email/password hash and remove evidence.
if [ ! -z "${EMAIL}" ] && [ ! -z "${EMAILPASS}" ]; then
#    echo "[smtp.gmail.com]:587    ${EMAIL}:${EMAILPASS}" > /etc/postfix/sasl_passwd
    echo "[SMTP.office365.com]:587    ${EMAIL}:${EMAILPASS}" > /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd
    #rm /etc/postfix/sasl_passwd
    ## remove FROM header, set reply-to, and insert FROM to be auth username
    ## tricky because you can't match the same line twice
    if [ ! -z "${FROMADDRESSMASQ}" ] && [ "${FROMADDRESSMASQ}" -eq 1 ]
    then
        exclusions=$(echo $MASQEXCLUSIONS | tr ',' '\n')
        echo '' > /etc/postfix/header_checks
        for addr in $exclusions
        do
                echo "/From(.*$addr.*)/ PASS no masquerade of this from address${1}" >> /etc/postfix/header_checks
        done
        echo '/From:(.*)/ REPLACE Reply-To:${1}' >> /etc/postfix/header_checks
        echo "/To:(.*)/ PREPEND From: $EMAIL" >> /etc/postfix/header_checks
    else
        echo > /etc/postfix/header_checks
    fi
    echo "postfix EMAIL/EMAILPASS combo is setup."
else
    echo "EMAIL or EMAILPASS not set!"
fi
unset EMAIL
unset EMAILPASS

chown -R postfix.postfix /var/spool/postfix
