# netatalk - (servercontainers/netatalk) [x86 + arm]

netatalk on alpine

* 2020-10-16
    * port from debian to alpine (debian version is available as tag)
    * way smaller now
    * no compiling
    * added timemachine and zeroconf support
* 2020-10-15
    * complete rework and multi arch builds

## Info

So for TimeMachine I can recommend using this container. If you want simple filesharing I'd recommend samba, webdav or other stuff.

Apple announced to deprecate afp and move to samba.

## Environment variables and defaults

### Netatalk

*  __NETATALK\_GLOBAL\_CONFIG\_someuniquevalue__
    * add any global netatalk config to `afp.conf`
    * example value: `mimic model = RackMac`

* __ACCOUNT\_username__
    * multiple variables/accounts possible
    * adds a new user account with the given username and the env value as password

to restrict access of volumes you can add the following to your netatalk volume config:

    valid users = alice; invalid users = bob;

* __NETATALK\_VOLUME\_CONFIG\_myconfigname__
    * adds a new netatalk volume configuration
    * multiple variables/confgurations possible by adding unique configname to NETATALK_VOLUME_CONFIG_
    * take a look at http://netatalk.sourceforge.net/3.0/htmldocs/afp.conf.5.html -> EXPLANATION OF VOLUME PARAMETERS
    * note only one `time machine = yes` is supported
    * examples
        * "[My Share]; path=/shares/myshare; valid users = alice; invalid users = bob;"
        * "[TimeCapsule Bob]; path=/shares/tc-bob; valid users = bob; vol size limit = 100000; time machine = yes"

## Some helpful indepth informations about TimeMachine and Avahi / Zeroconf 

### General Infos

- https://openwrt.org/docs/guide-user/services/nas/netatalk_configuration#zeroconf_advertising
- http://netatalk.sourceforge.net/wiki/index.php/Bonjour_record_adisk_adVF_values
- https://linux.die.net/man/5/avahi.service


You can't proxy the zeroconf inside the container to the outside, since this would need routing and forwarding to your internal docker0 interface from outside.
So you need to use the `network=host` mode to enable zeroconf from within the container

You can just expose the needed Port 548 to the docker hosts port and install avahi.
After that just add a new service which fits to your config.

### Configuration Examples (automatically generated inside the container)

__afp.conf__

    [Global]
      zeroconf = yes
      log file = /dev/stdout

    [Time Capsule]
      path = /timecapsule
      time machine = yes

__/etc/avahi/services/afdp.service__

    <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
    <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    <service-group>
        <name replace-wildcards="yes">%h</name>
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

