#!/bin/bash
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${BASE_DIR}/hook-lib.sh

# Get current DNS zone
DNS_ZONE="$(curl -s -w "\n%{http_code}" ${API_ENDPOINT}/list_records.json?apikey=${API_KEY} --data "client_id=${CLIENT_ID}&domain=${CERTBOT_DOMAIN}")"
[ "$(echo "$DNS_ZONE" | tail -1)" != "200" ] && log "ERROR: Did not get a 200 when querrying DNS zone, API return: 
$DNS_ZONE" && exit 1

# If there is an existing record we need to delete it first
if check_for_acme_record; then
	log "WARNING existing record for '_acme-challenge.${CERTBOT_DOMAIN}' found"

	ACME_RECORD_ID="$(echo "$ZONE_RECORD" | jq -r ".id")"
	DELETE_RECORD="$(curl -s -w "\n%{http_code}" ${API_ENDPOINT}/delete_record.json?apikey=${API_KEY} --data "client_id=${CLIENT_ID}&domain=${CERTBOT_DOMAIN}&record_id=${ACME_RECORD_ID}")"
[ "$(echo "$DELETE_RECORD" | tail -1)" != "200" ] && log "ERROR: Did not get a 200 when adding deleting record, API return: 
$ADD_RECORD" && exit 1
	log "Deleted record '_acme-challenge.${CERTBOT_DOMAIN}', sleeping for 60s..."
	sleep 60

fi

# Okay lets add the record
ADD_RECORD="$(curl -s -w "\n%{http_code}" ${API_ENDPOINT}/add_record.json?apikey=${API_KEY} --data "client_id=${CLIENT_ID}&domain=${CERTBOT_DOMAIN}&type=TXT&name=_acme-challenge.${CERTBOT_DOMAIN}&content=${CERTBOT_VALIDATION}")"
[ "$(echo "$ADD_RECORD" | tail -1)" != "200" ] && log "ERROR: Did not get a 200 when adding validation record, API return: 
$ADD_RECORD" && exit 1

# Wait for it to flow through the SiteHost scheduler
log "Waiting for record to exist in zone..."
while true; do
	check_for_acme_record && break
	log "Checking..."
	sleep 5
done

log "Digging and waiting 5 seconds for propigation."
dig TXT _acme-challenge.${CERTBOT_DOMAIN} > /dev/stderr
sleep 5

log "Ready to validate."
