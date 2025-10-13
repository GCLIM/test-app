#!/usr/bin/env bash
set -euo pipefail

# Wait timeout (seconds) for the token file
WAIT_TIMEOUT=30
SLEEP_INTERVAL=1

# Track previous token for change detection
PREV_TOKEN=""
FIRST_READ=true

k8s_authn_loop() {
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
      if [ "$FIRST_READ" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Conjur access token has been read from $CONJUR_AUTHN_TOKEN_FILE"
        FIRST_READ=false
      else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Conjur access token has changed!"
      fi
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

k8s_secrets_provider_loop() {
  while true; do
    DB_VALUE="${DB_PASSWORD:-<not set>}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Current DB_PASSWORD environment variable: $DB_VALUE"
    sleep 60
  done
}

# Main script execution starts here

case "$DEMO_MODE" in
  authn-k8s)
    echo "Demo Mode: Conjur K8s Authenticator"
    echo
    echo "This demo app will query for Conjur access token every 1 minute and fetch the secret value."
    echo
    k8s_authn_loop
    ;;
  secrets-provider-k8s)
    echo "Demo Mode: Conjur Secrets Provider for K8s"
    echo
    echo "This demo app will query K8s secrets every 1 minute and fetch the secret value."
    echo
    k8s_secrets_provider_loop
    ;;
  *)
    echo "Error: Unknown DEMO_MODE '$DEMO_MODE'."
    echo "Valid options: authn-k8s | secrets-provider-k8s"
    exit 1
    ;;
esac

# End of script