#!/bin/bash

export IFS=$'\n'

cat <<EOF
################################################################################

Welcome to the servercontainers/netatalk

################################################################################

EOF

INITALIZED="/.initialized"

if [ ! -f "$INITALIZED" ]; then
  echo ">> CONTAINER: starting initialisation"

  cp /container/config/avahi/afp.service /etc/avahi/services/afp.service

  ##
  # GLOBAL CONFIGURATION
  ##
  for I_CONF in $(env | grep '^NETATALK_GLOBAL_CONFIG_')
  do
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')
    echo ">> global config - adding: '$CONF_CONF_VALUE' to /etc/afp.conf"
    sed -i '/\[Global\]/a\  '"$CONF_CONF_VALUE" /etc/afp.conf
  done

  ##
  # USER ACCOUNTS
  ##
  for I_ACCOUNT in $(env | grep '^ACCOUNT_')
  do
    ACCOUNT_NAME=$(echo "$I_ACCOUNT" | cut -d'=' -f1 | sed 's/ACCOUNT_//g' | tr '[:upper:]' '[:lower:]')
    ACCOUNT_PASSWORD=$(echo "$I_ACCOUNT" | sed 's/^[^=]*=//g')

    echo ">> ACCOUNT: adding account: $ACCOUNT_NAME"
    adduser -H -s /bin/false "$ACCOUNT_NAME"
    echo -e "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | passwd "$ACCOUNT_NAME"

    unset $(echo "$I_ACCOUNT" | cut -d'=' -f1)
  done

  ##
  # Netatalk Volume Config ENVs
  ##
  for I_CONF in $(env | grep '^NETATALK_VOLUME_CONFIG_')
  do
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')

    # if time machine volume
    if echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' | grep time\ machine | grep yes 2>/dev/null >/dev/null;
    then
        sed -i 's,</service-group>,,g' /etc/avahi/services/afp.service

        VOL_NAME=$(echo "$CONF_CONF_VALUE" | sed 's/.*\[\(.*\)\].*/\1/g')
        VOL_PATH=$(echo "$CONF_CONF_VALUE" | tr ';' '\n' | grep path | sed 's/.*= *//g')
        echo ">> TIMEMACHINE: adding volume to zeroconf: $VOL_NAME"
        if [ ! -f "$VOL_PATH/.netatalk-volume-uuid" ]
        then
          UUID=$(cat /proc/sys/kernel/random/uuid)
          echo "$UUID" > "$VOL_PATH/.netatalk-volume-uuid"
          echo ">> TIMEMACHINE: creating new random uuid: $UUID"
        fi
        UUID=$(cat "$VOL_PATH/.netatalk-volume-uuid")

        env | grep mimic 2>/dev/null >/dev/null && MODEL=$(env | grep mimic | sed 's/.*model *= *//g') || MODEL="TimeCapsule"

        if ! grep '<txt-record>model=' /etc/avahi/services/afp.service 2> /dev/null >/dev/null;
        then
          echo ">> TIMEMACHINE: zeroconf model: $MODEL"
          echo '
  <service>
   <type>_device-info._tcp</type>
   <port>0</port>
   <txt-record>model='"$MODEL"'</txt-record>
  </service>' >> /etc/avahi/services/afp.service
        fi

        NUMBER=$(env | grep time\ machine | grep -n "$VOL_PATH" | grep "\[$VOL_NAME\]" | sed 's/^\([0-9]*\):.*/\1/g' | head -n1)

        echo '
  <service>
   <type>_adisk._tcp</type>
   <port>9</port>
   <txt-record>sys=waMa=0,adVF=0x100,adVU='"$UUID"'</txt-record>
   <txt-record>dk'"$NUMBER"'=adVN='"$VOL_NAME"',adVF=0x81</txt-record>
  </service>
</service-group>' >> /etc/avahi/services/afp.service
    fi

    echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' >> /etc/afp.conf
    echo "" >> /etc/afp.conf

  done

  echo ">> ZEROCONF: afp.service file"
  echo "############################### START ####################################"
  cat /etc/avahi/services/afp.service
  echo "################################ END #####################################"

  touch "$INITALIZED"
else
  echo ">> CONTAINER: already initialized - direct start of netatalk"
fi

##
# CMD
##
echo ">> CMD: exec docker CMD"
echo "$@"
exec "$@"
