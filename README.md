# still under construction

# netatalk
3.1.11 netatalk - freshly complied from official stable releases on debian:jessie

# Source Code
Check the following link for a new version: https://sourceforge.net/projects/netatalk/files/netatalk

## Environment variables and defaults

### Netatalk

* __ACCOUNT\_username__
    * multiple variables/accounts possible
    * adds a new user account with the given username and the env value as password

to enable authentication add the following to your netatalk config:

    auth_basic "Restricted Area"; auth_basic_user_file /conf/auth.htpasswd;

* __NETATALK\_VOLUME\_CONFIG\_myconfigname__
    * adds a new netatalk volume configuration
    * multiple variables/confgurations possible by adding unique configname to NETATALK_VOLUME_CONFIG_
    * take a look at http://netatalk.sourceforge.net/3.0/htmldocs/afp.conf.5.html -> EXPLANATION OF VOLUME PARAMETERS
    * examples
        * "[My Share]; path=/shares/myshare; valid users = alice; invalid users = bob;"
        * "[TimeCapsule Bob]; path=/shares/tc-bob; valid users = bob; vol size limit = 100000; time machine = yes"

# TimeMachine - Avahi / Zeroconf

## Infos:

* https://linux.die.net/man/5/avahi.service
* http://netatalk.sourceforge.net/wiki/index.php/Bonjour_record_adisk_adVF_values

You can't proxy the zeroconf inside the container to the outside, since this would need routing and forwarding to your internal docker0 interface from outside.

You can just expose the needed Port 548 to the docker hosts port and install avahi.
After that just add a new service which fits to your config.

### Example Configuration

__afp.conf__

    [Global]
      zeroconf = no
      log file = /dev/stdout

    [Time Capsule]
      path = /timecapsule
      time machine = yes

__/etc/avahi/services/afdp.service__

    <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
    <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    <service-group>
        <name replace-wildcards="yes">Time Capsule</name>
        <service>
            <type>_afpovertcp._tcp</type>
            <port>548</port>
        </service>
        <service>
            <type>_adisk._tcp</type>
            <port>9</port>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
            <txt-record>dk0=adVF=0xa1,adVN=Time Capsule</txt-record>
        </service>
        <service>
            <type>_device-info._tcp</type>
            <port>0</port>
            <txt-record>model=RackMac</txt-record>
        </service>
    </service-group>
