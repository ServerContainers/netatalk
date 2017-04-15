FROM debian:jessie

RUN export netatalk_version=3.1.11 \
 && export DEBIAN_FRONTEND=noninteractive \
 \
 && apt-get -q -y update \
 && apt-get -q -y install build-essential \
                          wget \
 && apt-get -q -y install pkg-config \
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
                          libgcrypt11-dev \
                          libtdb-dev \
                          libkrb5-dev \
 \
 && apt-get -q -y clean \
 \
 && wget http://prdownloads.sourceforge.net/netatalk/netatalk-${netatalk_version}.tar.gz \
 && tar xvf netatalk-${netatalk_version}.tar.gz \
 && rm netatalk-${netatalk_version}.tar.gz \
 && cd netatalk-${netatalk_version} \
 && ./configure --prefix=/ \
		--enable-debian-systemd \
		--enable-krbV-uam \
		--disable-zeroconf \
		--enable-krbV-uam \
		--enable-tcp-wrappers \
		--with-cracklib \
		--with-acls \
		--with-dbus-sysconf-dir=/etc/dbus-1/system.d \
		--with-init-style=debian-systemd \
		--with-pam-confdir=/etc/pam.d && \
 && make \
 && checkinstall \
		--pkgname=netatalk \
		--pkgversion=$netatalk_version \
		--backup=no \
		--deldoc=yes \
		--default \
		--fstrans=no \
 && cd - \
 && rm -rf netatalk-${netatalk_version} \
 && sed -i 's/\[Global\]/[Global]\n  afp interfaces = eth0\n  log file = \/dev\/stdout\n  log level = default:warn\n  zeroconf = no/g' /etc/afp.conf

EXPOSE 548

CMD [ "/sbin/netatalk", "-d", "-F", "/etc/afp.conf" ]
