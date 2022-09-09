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

# Set FROMADDRESSMASQ unless explicitly set to zero
if [ ! -z "${FROMADDRESSMASQ}" ] || [ "${FROMADDRESSMASQ}" -ne 0 ]; then
    echo 'setting $FROMADDRESSMASQ = 1'
    FROMADDRESSMASQ=1
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
        echo '' > /etc/postfix/header_checks
        echo '/[Ff]rom:(.*)/ PREPEND Reply-To:${1}' >> /etc/postfix/header_checks
        exclusions=$(echo $MASQEXCLUSIONS | sed 's/\./\\./g' | tr ',' '\n')
        echo '' > /etc/postfix/smtp_header_checks
        for addr in $exclusions
        do
                echo "/[Ff]rom=( *?)(<$addr.*?>)/ DUNNO no masquerade of this from address \${1}" >> /etc/postfix/smtp_header_checks
        done
        echo "/[Ff]rom=( *?)(<.*?>)/ REPLACE From: <$EMAIL>" >> /etc/postfix/smtp_header_checks
    else
        echo '' > /etc/postfix/header_checks
        echo '' > /etc/postfix/smtp_header_checks
    fi
    echo "postfix EMAIL/EMAILPASS combo is setup."
else
    echo "EMAIL or EMAILPASS not set!"
fi
unset EMAIL
unset EMAILPASS

chown -R postfix.postfix /var/spool/postfix
