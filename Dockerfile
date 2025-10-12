# Use a lightweight Alpine base image
FROM alpine:3.20

# Metadata
LABEL maintainer="GChuan Lim" \
      description="Container to retrieve a secret from CyberArk Conjur using a Bash script."

# Install required packages
# bash - for the script
# curl - for making API calls to Conjur
# coreutils - for base64
# jq - optional, useful for parsing JSON or URI encoding
RUN apk add --no-cache bash curl coreutils jq

# Set working directory
WORKDIR /app

# Copy your Conjur retrieval script into the container
COPY retrieve_conjur_secret.sh /app/retrieve_conjur_secret.sh

# Make it executable
RUN chmod +x /app/retrieve_conjur_secret.sh

# Default environment variables (can be overridden at runtime)
# ENV CONJUR_APPLIANCE_URL="https://conjur01.gcloud101.com" \
#     CONJUR_ACCOUNT="default" \
#     CONJUR_AUTHN_TOKEN_FILE="/run/conjur/access-token" \
#     VAR_ID="secrets/test-variable"

ENV CONJUR_AUTHN_TOKEN_FILE="/run/conjur/access-token"

# Run the script by default
ENTRYPOINT ["/app/retrieve_conjur_secret.sh"]

