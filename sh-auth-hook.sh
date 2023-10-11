#!/bin/bash
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${BASE_DIR}/hook-lib.sh

# If there is an existing record we need to delete it first
if check_for_acme_record; then
	log "WARNING existing record for '_acme-challenge.${CERTBOT_DOMAIN}' found"

	ACME_RECORD_ID="$(echo "$ZONE_RECORD" | jq -r ".id")"
	DELETE_RECORD="$(curl -s -w "\n%{http_code}" ${API_ENDPOINT}/delete_record.json?apikey=${API_KEY} --data "client_id=${CLIENT_ID}&domain=${CERTBOT_DOMAIN}&record_id=${ACME_RECORD_ID}")"
	[ "$(echo "$DELETE_RECORD" | tail -1)" != "200" ] && log "ERROR: Did not get a 200 when deleting record, API return: 
$ADD_RECORD" && exit 1
	log "Deleted record '_acme-challenge.${CERTBOT_DOMAIN}'"
	sleep 5

fi

# Okay lets add the record
ADD_RECORD="$(curl -s -w "\n%{http_code}" ${API_ENDPOINT}/add_record.json?apikey=${API_KEY} --data "client_id=${CLIENT_ID}&domain=${CERTBOT_DOMAIN}&type=TXT&name=_acme-challenge.${CERTBOT_DOMAIN}&content=${CERTBOT_VALIDATION}")"
[ "$(echo "$ADD_RECORD" | tail -1)" != "200" ] && log "ERROR: Did not get a 200 when adding validation record, API return: 
$ADD_RECORD" && exit 1

# Wait for it to flow through the SiteHost scheduler
log "Waiting for record to exist in zone..."
while ! check_for_acme_record; do
	log "Checking..."
	sleep 5
done

log "Digging and waiting for the new record to propigate..."
while true; do
	CURRENT_RECORD="$(dig TXT _acme-challenge.${CERTBOT_DOMAIN} +short | sed 's/"//g')"
	if [ "${CURRENT_RECORD}" == "${CERTBOT_VALIDATION}" ]; then break; fi
	log "New record has not propigated yet, waiting 10 seconds..."
	sleep 10
done

log "Ready to validate."
