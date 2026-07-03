FROM confluentinc/cp-kafka-connect-base:7.9.4

LABEL org.opencontainers.image.title="JDBC Kafka Connect"
LABEL org.opencontainers.image.description="Kafka Connect image with JDBC plugin and Proxychains"
LABEL org.opencontainers.image.authors="ANTHONY-LEWANDOWSKI"
LABEL org.opencontainers.image.source=""
LABEL org.opencontainers.image.vendor=""
LABEL org.opencontainers.image.licenses=""

ENV PROXYCHAIN_CONF=/etc/proxychains/proxychains.conf \
    ENTRYPOINT_HOME=/scripts \
    ENTRYPOINT_NAME=entrypoint.sh \
    CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components" \
    USER=appuser \
    USER_HOME=/home/appuser \
    KAFKA_HOME=/kafka

USER root

RUN set -e && \
    yum clean all && rm -rf /var/cache/yum/* && \
    yum install -y wget gcc make unzip jq && \
    wget https://github.com/rofl0r/proxychains-ng/archive/master.zip && \
    unzip master.zip && \
    cd proxychains-ng-master && \
    ./configure --prefix=/usr --sysconfdir=/etc && \
    make && \
    make install && \
    make install-config && \
    cd .. && \
    rm -rf master.zip proxychains-ng-master && \
    mkdir -p "$ENTRYPOINT_HOME" "$KAFKA_HOME" && \
    chown -R "$USER:$USER" "$ENTRYPOINT_HOME" "$KAFKA_HOME"

COPY entrypoint/proxychains.conf $PROXYCHAIN_CONF
COPY entrypoint/entrypoint.sh $ENTRYPOINT_HOME/$ENTRYPOINT_NAME
COPY scripts/healthy.sh $ENTRYPOINT_HOME/healthy.sh

RUN chmod +x "$ENTRYPOINT_HOME/$ENTRYPOINT_NAME" "$ENTRYPOINT_HOME/healthy.sh"

USER $USER
WORKDIR $USER_HOME

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.9.0

ENTRYPOINT ["/bin/bash", "/scripts/entrypoint.sh"]
