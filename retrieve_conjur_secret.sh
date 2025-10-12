#!/usr/bin/env bash
set -euo pipefail

# Name of secret to retrieve from Conjur
VAR_ID="secrets/test-variable"

# Wait timeout (seconds) for the token file
WAIT_TIMEOUT=30
SLEEP_INTERVAL=1

# Track previous token for change detection
PREV_TOKEN=""

main_loop() {
  while true; do
    # Wait until token file exists
    local waited=0
    while [ ! -f "$CONJUR_AUTHN_TOKEN_FILE" ]; do
      if [ "$waited" -ge "$WAIT_TIMEOUT" ]; then
        echo "Error: Timeout waiting for token file: $CONJUR_AUTHN_TOKEN_FILE" >&2
        exit 1
      fi
      sleep "$SLEEP_INTERVAL"
      waited=$((waited + SLEEP_INTERVAL))
    done

    # Read and encode token
    CONT_SESSION_TOKEN=$(base64 < "$CONJUR_AUTHN_TOKEN_FILE" | tr -d '\r\n')

    # Check if token changed
    if [ "$CONT_SESSION_TOKEN" != "$PREV_TOKEN" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') - Conjur access token has changed!"
      PREV_TOKEN="$CONT_SESSION_TOKEN"
    fi

    # URL-encode the variable ID
    urlify "$VAR_ID"
    VAR_ID_ENCODED="$URLIFIED"

    # Retrieve secret value
    VAR_VALUE=$(curl -s -k \
      --request GET \
      -H "Content-Type: application/json" \
      -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" \
      "$CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$VAR_ID_ENCODED")

    # Print secret with timestamp
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Retrieved secret value: $VAR_VALUE"

    # Wait 1 minute before next iteration
    sleep 60
  done
}

################
# URLIFY - converts '/' and ':' in input string to hex equivalents
# in: $1 - string to convert
# out: URLIFIED - converted string in global variable
urlify() {
  local str=$1
  str=$(echo "$str" | sed 's= =%20=g; s=/=%2F=g; s=:=%3A=g')
  URLIFIED=$str
}

main_loop
