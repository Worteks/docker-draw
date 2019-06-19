#!/bin/sh

if test "$DEBUG"; then
    set -x
fi

if test "`id -u`" -ne 0; then
    echo Setting up nsswrapper mapping `id -u` to drawio
    sed "s|^drawio:.*|drawio:x:`id -g`:|" /etc/group >/tmp/drawio-group
    sed \
	"s|^drawio:.*|drawio:x:`id -u`:`id -g`:drawio:/var/www:/usr/sbin/nologin|" \
	/etc/passwd >/tmp/drawio-passwd
    export NSS_WRAPPER_PASSWD=/tmp/drawio-passwd
    export NSS_WRAPPER_GROUP=/tmp/drawio-group
    export LD_PRELOAD=/usr/lib/libnss_wrapper.so
fi

exec "$@"
