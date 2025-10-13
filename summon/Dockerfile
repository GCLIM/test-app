# ============ BUILD STAGE ============ #
FROM alpine:3.20 AS builder
LABEL stage="builder"

# Install required tools
RUN apk add --no-cache curl bash

# Install summon and summon-conjur
RUN set -eux; \
    TMPDIR=$(mktemp -d); \
    curl -sSL https://raw.githubusercontent.com/cyberark/summon/main/install.sh | TMPDIR=$TMPDIR bash; \
    TMPDIR=$(mktemp -d); \
    curl -sSL https://raw.githubusercontent.com/cyberark/summon-conjur/main/install.sh | TMPDIR=$TMPDIR bash

# ============ FINAL STAGE ============ #
FROM alpine:3.20
LABEL maintainer="GC Lim" \
      description="Container to retrieve a secret from CyberArk Conjur using a Bash script."

# Install runtime dependencies
RUN apk add --no-cache bash curl coreutils jq

# Copy summon binaries from builder
COPY --from=builder /usr/local/lib/summon /usr/local/lib/summon
COPY --from=builder /usr/local/bin/summon /usr/local/bin/summon

# Copy secrets file and script
COPY summon/secrets.yml /etc/secrets.yml
COPY summon/retrieve_conjur_secret.sh /app/retrieve_conjur_secret.sh
WORKDIR /app

# Make script executable
RUN chmod +x retrieve_conjur_secret.sh

# Run script wrapped with summon
ENTRYPOINT ["summon", "--provider", "summon-conjur", "-f", "/etc/secrets.yml", "/app/retrieve_conjur_secret.sh"]


