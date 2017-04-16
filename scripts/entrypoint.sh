#!/bin/sh

cat <<EOF
################################################################################

Welcome to the servercontainers/netatalk

################################################################################

EOF

INITALIZED="/.initialized"

if [ ! -f "$INITALIZED" ]; then
  echo ">> CONTAINER: starting initialisation"

  ##
  # USER ACCOUNTS
  ##
  for I_ACCOUNT in "$(env | grep '^ACCOUNT_')"
  do
    ACCOUNT_NAME=$(echo "$I_ACCOUNT" | cut -d'=' -f1 | sed 's/ACCOUNT_//g' | tr '[:upper:]' '[:lower:]')
    ACCOUNT_PASSWORD=$(echo "$I_ACCOUNT" | sed 's/^[^=]*=//g')

    echo ">> ACCOUNT: adding account: $ACCOUNT_NAME"
    useradd -M -s /bin/false "$ACCOUNT_NAME"
    echo "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | passwd "$ACCOUNT_NAME"

    unset $(echo "$I_ACCOUNT" | cut -d'=' -f1)
  done

  ##
  # Netatalk Vonlume Config ENVs
  ##
  for I_CONF in "$(env | grep '^NETATALK_VOLUME_CONFIG_')"
  do
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')

    echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' >> /etc/afp.conf
    echo "" >> /etc/afp.conf
  done

  touch "$INITALIZED"
else
  echo ">> CONTAINER: already initialized - direct start of netatalk"
fi

cat /etc/afp.conf
##
# CMD
##
echo ">> CMD: exec docker CMD"
echo "$@"
exec "$@"
