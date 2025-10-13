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
    urlify "$VARIABLE_ID"
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

k8s_authn_summon_loop() {
  while true; do
    MyDemoSecret="${MyDemoSecret:-<not set>}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Current MyDemoSecret environment variable: $MyDemoSecret"
    sleep 60
  done
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
    echo "Demo Mode: Conjur Kubernetes Authenticator"
    echo ""
    echo "The Conjur Kubernetes Authenticator obtains a short-lived access token from Conjur."
    echo "This token is stored using shared memory volume specified by CONJUR_AUTHN_TOKEN_FILE."
    echo "In this demo, the application reads the token and uses it to authenticate with Conjur to retrieve a secret."
    echo "The variable ID to retrieve is specified by VARIABLE_ID environment variable."
    echo ""
    k8s_authn_loop
    ;;
  authn-k8s-summon)
    echo "Demo Mode: Conjur Kubernetes Authenticator with Summon Secrets Injection"
    echo ""
    echo "The Conjur Kubernetes Authenticator obtains a short-lived access token from Conjur."
    echo "This token is stored using shared memory volume specified by CONJUR_AUTHN_TOKEN_FILE."
    echo "In this demo, the application uses Summon to reads the token, authenticate with Conjur and inject secret."
    echo "The environment variable to store the secret value is specified in secrets.yml file."
    echo ""
    cat /etc/secrets.yml
    k8s_authn_summon_loop
    ;;
  secrets-provider-k8s)
    echo "Demo Mode: Conjur Secrets Provider for Kubernetes"
    echo ""
    echo "The Conjur Secrets Provider for Kubernetes retrieves secrets from Conjur and updates them in a Kubernetes Secret."
    echo "In this demo, the application starts and consumes the secret as the environment variable: DB_PASSWORD."
    echo ""
    k8s_secrets_provider_loop
    ;;
  *)
    echo "Error: Unknown DEMO_MODE '$DEMO_MODE'."
    echo "Valid options: authn-k8s | secrets-provider-k8s | authn-k8s-summon"
    exit 1
    ;;
esac

# End of script