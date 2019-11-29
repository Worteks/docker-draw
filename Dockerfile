FROM tomcat:9-jre11-slim

# Draw.io image for OpenShift Origin

LABEL io.k8s.description="Draw.io is a Java based diagram solution." \
      io.k8s.display-name="Draw.io 12.3.2" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="diagram,draw,drawio,drawio1232" \
      io.openshift.non-scalable="false" \
      help="For more information visit https://github.com/Worteks/docker-draw" \
      maintainer="Thibaut DEMARET <thidem@worteks.com>, Samuel MARTIN MORO <sammar@worteks.com>" \
      version="12.3.2"

ENV DEBIAN_FRONTEND=noninteractive \
    DI=https://github.com/Yelp/dumb-init/releases/download/ \
    DUMBINITVERSION=1.2.2 \
    VERSION=12.3.2

COPY config/* /
RUN echo "# Install Dumb-init" \
    && apt-get update \
    && apt-get -y install wget \
    && wget $DI/v${DUMBINITVERSION}/dumb-init_${DUMBINITVERSION}_amd64.deb \
	-O dumb-init.deb \
    && dpkg -i dumb-init.deb \
    && apt-get install -f -y \
    && if test "$DO_UPGRADE"; then \
	echo "# Upgrade Base Image"; \
	apt-get -y upgrade; \
	apt-get -y dist-upgrade; \
    fi \
    && echo "# Install Draw.io Dependencies" \
    && apt-get install -y --no-install-recommends openjdk-11-jdk-headless ant \
	git patch wget xmlstarlet certbot curl libnss-wrapper \
    && echo "# Install Draw.io" \
    && ( \
	cd /tmp \
	&& wget https://github.com/jgraph/draw.io/archive/v${VERSION}.zip \
	&& unzip v${VERSION}.zip \
	&& cd /tmp/drawio-${VERSION} \
	&& cd /tmp/drawio-${VERSION}/etc/build \
	&& ant war \
	&& cd /tmp/drawio-${VERSION}/build \
	&& unzip /tmp/drawio-${VERSION}/build/draw.war \
	    -d $CATALINA_HOME/webapps/draw; \
    ) \
    && apt-get remove -y --purge openjdk-11-jdk-headless ant git patch wget \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/v${VERSION}.zip /tmp/drawio-${VERSION} \
	dumb-init.deb

# Update server.xml to set Draw.io webapp to root
RUN cd $CATALINA_HOME && \
    xmlstarlet ed \
    -P -S -L \
    -i '/Server/Service/Engine/Host/Valve' -t 'elem' -n 'Context' \
    -i '/Server/Service/Engine/Host/Context' -t 'attr' -n 'path' -v '/' \
    -i '/Server/Service/Engine/Host/Context[@path="/"]' -t 'attr' -n 'docBase' -v 'draw' \
    -s '/Server/Service/Engine/Host/Context[@path="/"]' -t 'elem' -n 'WatchedResource' -v 'WEB-INF/web.xml' \
    -i '/Server/Service/Engine/Host/Valve' -t 'elem' -n 'Context' \
    -i '/Server/Service/Engine/Host/Context[not(@path="/")]' -t 'attr' -n 'path' -v '/ROOT' \
    -s '/Server/Service/Engine/Host/Context[@path="/ROOT"]' -t 'attr' -n 'docBase' -v 'ROOT' \
    -s '/Server/Service/Engine/Host/Context[@path="/ROOT"]' -t 'elem' -n 'WatchedResource' -v 'WEB-INF/web.xml' \
    conf/server.xml

USER 1001
WORKDIR $CATALINA_HOME
ENTRYPOINT ["dumb-init","--","/run-draw.sh"]
CMD "catalina.sh" "run"
