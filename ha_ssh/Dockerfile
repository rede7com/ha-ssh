ARG BUILD_FROM
FROM $BUILD_FROM

RUN apk add --no-cache openssh curl docker-cli rsync util-linux

COPY rootfs /

RUN chmod a+x /etc/cont-init.d/00-setup-ssh.sh \
    && chmod a+x /etc/services.d/ssh/run \
    && chmod a+x /etc/services.d/ssh/finish \
    && chmod a+x /usr/bin/ha-api
