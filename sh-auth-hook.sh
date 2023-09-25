#!/bin/bash
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${BASE_DIR}/hook-lib.sh

# Get current DNS zone
DNS_ZONE="$(curl -s -w "\n%{http_code}" ${API_ENDPOINT}/list_records.json?apikey=${API_KEY} --data "client_id=${CLIENT_ID}&domain=${CERTBOT_DOMAIN}")"
[ "$(echo "$DNS_ZONE" | tail -1)" != "200" ] && log "ERROR: Did not get a 200 when querrying DNS zone, API return: 
$DNS_ZONE" && exit 1

# TODO test this
# Check to see if there is an existing acme record
#if [ ! -z "$(echo "$DNS_ZONE" | head -1 | jq ".return[] | select(.type==\"TXT\" and .name==\"_acme-challenge.${CERBOT_DOMAIN}\")")" ]; then
#	# Uh oh, we need to wait around for a while
#
#	log "WARNING existing record for '_acme-challenge.${CERBOT_DOMAIN}' found, deleting an sleeping for 60 seconds..."
#	#sleep 60
#	#TODO add record delete
#fi

# Okay lets add the record
ADD_RECORD="$(curl -s -w "\n%{http_code}" ${API_ENDPOINT}/add_record.json?apikey=${API_KEY} --data "client_id=${CLIENT_ID}&domain=${CERTBOT_DOMAIN}&type=TXT&name=_acme-challenge.${CERTBOT_DOMAIN}&content=${CERTBOT_VALIDATION}")"
[ "$(echo "$ADD_RECORD" | tail -1)" != "200" ] && log "ERROR: Did not get a 200 when adding validation record, API return: 
$ADD_RECORD" && exit 1

# Give it a second to flow through the SiteHost scheduler
# TODO could poll for it here
sleep 5

