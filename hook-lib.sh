#!/bin/bash
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source config
source ${BASE_DIR}/defaults.config
[ -f ${BASE_DIR}/config ] && source ${BASE_DIR}/config

function log {
  DATESTRING=$(date -u '+%F %X')
  echo -e "$DATESTRING | $1" > /dev/stderr
}

# Catch errors
[ -z "${API_KEY}" ] && log "ERROR: API_KEY is not defined!" && exit 1
[ -z "${CLIENT_ID}" ] && log "ERROR: CLIENT_ID is not defined!" && exit 1

# Make sure we got the LE env vars
[ -z "$CERTBOT_DOMAIN" ] && log "ERROR: CERTBOT_DOMAIN is not defined!" && exit 1
[ -z "$CERTBOT_VALIDATION" ] && log "ERROR: CERTBOT_DOMAIN is not defined!" && exit 1

# Check to see if there is an existing acme record
function check_for_acme_record {
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
