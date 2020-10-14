FROM debian:buster

RUN export netatalk_version=3.1.12 \
 && export DEBIAN_FRONTEND=noninteractive \
 \
 && apt-get -q -y update \
 && apt-get -q -y install build-essential \
                          wget \
 && apt-get -q -y install pkg-config \
                          runit \
                          avahi-daemon \
                          checkinstall \
                          automake \
                          libtool \
                          db-util \
                          db5.3-util \
                          libcrack2-dev \
                          libwrap0-dev \
                          autotools-dev \
                          libdb-dev \
                          libacl1-dev \
                          libdb5.3-dev \
                          libgcrypt20-dev \
                          libtdb-dev \
                          libkrb5-dev \
                          libavahi-client-dev \
 \
 && apt-get -q -y clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 \
 && wget http://prdownloads.sourceforge.net/netatalk/netatalk-${netatalk_version}.tar.gz \
 && tar xvf netatalk-${netatalk_version}.tar.gz \
 && rm netatalk-${netatalk_version}.tar.gz \
 && cd netatalk-${netatalk_version} \
 \
 && ./configure --prefix= \
		--enable-debian-systemd \
		--enable-krbV-uam \
		--enable-zeroconf \
		--enable-krbV-uam \
		--enable-tcp-wrappers \
		--with-cracklib \
		--with-acls \
		--with-dbus-sysconf-dir=/etc/dbus-1/system.d \
		--with-init-style=debian-systemd \
		--with-pam-confdir=/etc/pam.d \
 && make \
 && checkinstall \
		--pkgname=netatalk \
		--pkgversion=$netatalk_version \
		--backup=no \
		--deldoc=yes \
		--default \
		--fstrans=no \
 \
 && cd - \
 && rm -rf netatalk-${netatalk_version} \
 && sed -i 's/\[Global\]/[Global]\n  log file = \/dev\/stdout\n  zeroconf = yes/g' /etc/afp.conf \
 && echo "" >> /etc/afp.conf

VOLUME ["/shares"]
EXPOSE 548

COPY . /container/

HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]
ENTRYPOINT ["/container/scripts/entrypoint.sh"]

CMD [ "runsvdir","-P", "/container/config/runit" ]
