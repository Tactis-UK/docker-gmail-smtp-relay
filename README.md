```
Docker Build/ Run SMTP (for use by Jenkins Master):

# Clone
git clone https://github.com/RaderSolutions/docker-o365-smtp-relay.git
cd docker-o365-smtp-relay/

# Build docker container
docker build -t o365-smtp-relay .

# Start docker container (--detach to run in background) 
docker run --detach --restart unless-stopped \
	-p 25:25 \
	-e SYSTEM_TIMEZONE="America/Chicago" \
	-e MYNETWORKS="10.0.0.0/8 192.168.0.0/16 172.16.0.0/12" \
	-e EMAIL="user@domain.com" \
	-e EMAILPASS="the-password" \
	--name o365-smtp-relay \
	o365-smtp-relay

# To test
sendemail -f jim@bbc.com -t jim@bbc.com -u subject -m "RelayedViaOffice365" -s localhost:25 -o tls=no

# Stop (and remove otherwise the name is help on to)
docker stop smtp-relay && docker rm smtp-relay
```


# Parameters

 - FROMADDRESSMASQ
   - Set to `1` if you want the `From:` header to be rewritten to be the authenticated user. If this is set, the original `From:` address will be set to be the `Reply-To:` address.
 - MASQEXCLUSIONS
   - comma-separated list of message header matches to exclude messages from the "From" masquerading. Ignored if FROMADDRESSMASQ is not `1`
 - MYNETWORKS
   - Space-separated list of networks to allow relay from
