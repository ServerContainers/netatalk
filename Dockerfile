FROM alpine
# alpine:3.12

ENV PATH="/container/scripts:${PATH}"

RUN apk add --no-cache runit \
                       bash \
                       dbus \
                       avahi \
                       netatalk \
 \
 && sed -i 's/\[Global\]/[Global]\n  log file = \/dev\/stdout\n  zeroconf = yes/g' /etc/afp.conf \
 && echo "" >> /etc/afp.conf

VOLUME ["/shares"]
EXPOSE 548

COPY . /container/

HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]
ENTRYPOINT ["/container/scripts/entrypoint.sh"]

CMD [ "runsvdir","-P", "/container/config/runit" ]
