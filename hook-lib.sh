#!/bin/bash
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source config
source ${BASE_DIR}/defaults.config
[ -f ${BASE_DIR}/config ] && source ${BASE_DIR}/config

function log {
  DATESTRING=$(date -u '+%F %X')
  echo -e "$DATESTRING | $1"
}

# Catch errors
[ -z "${API_KEY}" ] && log "ERROR: API_KEY is not defined!" && exit 1
[ -z "${CLIENT_ID}" ] && log "ERROR: CLIENT_ID is not defined!" && exit 1

# Make sure we got the LE env vars
[ -z "$CERTBOT_DOMAIN" ] && log "ERROR: CERTBOT_DOMAIN is not defined!" && exit 1
[ -z "$CERTBOT_VALIDATION" ] && log "ERROR: CERTBOT_DOMAIN is not defined!" && exit 1

log "DEBUG: token '$CERTBOT_VALIDATION' domain 'CERTBOT_DOMAIN'"

# Check to see if there is an existing acme record
function check_for_acme_record {

	# Get current DNS zone
	DNS_ZONE="$(curl -s -w "\n%{http_code}" ${API_ENDPOINT}/list_records.json?apikey=${API_KEY} --data "client_id=${CLIENT_ID}&domain=${CERTBOT_DOMAIN}")"
	[ "$(echo "$DNS_ZONE" | tail -1)" != "200" ] && log "ERROR: Did not get a 200 when querrying DNS zone, API return:
$DNS_ZONE" && exit 1

  log "Checking for ACME record '_acme-challenge.${CERTBOT_DOMAIN}'"
  ZONE_RECORD="$(echo "$DNS_ZONE" | head -1 | jq ".return[] | select(.type==\"TXT\" and .name==\"_acme-challenge.${CERTBOT_DOMAIN}\")")"
  if [ ! -z "$ZONE_RECORD" ]; then
    log "Record '_acme-challenge.${CERTBOT_DOMAIN}' found: $ZONE_RECORD"
    return 0
  else
    log "Record '_acme-challenge.${CERTBOT_DOMAIN}' not found"
    return 1
  fi

}
