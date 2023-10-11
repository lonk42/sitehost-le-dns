#!/bin/bash
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${BASE_DIR}/hook-lib.sh

# We are done now so lets delete the acme record to make new renewal faster
if check_for_acme_record; then
	log "WARNING existing record for '_acme-challenge.${CERTBOT_DOMAIN}' found, if the cert was sign successfully I am confused."

	ACME_RECORD_ID="$(echo "$ZONE_RECORD" | jq -r ".id")"
	DELETE_RECORD="$(curl -s -w "\n%{http_code}" ${API_ENDPOINT}/delete_record.json?apikey=${API_KEY} --data "client_id=${CLIENT_ID}&domain=${CERTBOT_DOMAIN}&record_id=${ACME_RECORD_ID}")"
	[ "$(echo "$DELETE_RECORD" | tail -1)" != "200" ] && log "ERROR: Did not get a 200 when deleting record, API return: 
$ADD_RECORD" && exit 1
	log "Deleted record '_acme-challenge.${CERTBOT_DOMAIN}'"

fi

# Restart any systemd daemons we have been instructed to do
while read SYSTEMD_DAEMON; do
	log "Restarting $SYSTEMD_DAEMON.."
	systemctl restart $SYSTEMD_DAEMON
done < <(echo "$SYSTEMD_RESTART_DAEMONS")
