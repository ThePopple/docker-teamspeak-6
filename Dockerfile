FROM ich777/debian-baseimage

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/popplej/docker-teamspeak-6"

RUN apt-get update && \
	apt-get -y install --no-install-recommends curl jq bzip2 wget && \
	rm -rf /var/lib/apt/lists/*

ENV DATA_DIR="/teamspeak"
ENV TSSERVER_LICENSE_ACCEPTED=""
ENV EXTRA_START_PARAMS=""
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="teamspeak"

RUN mkdir $DATA_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
RUN chmod -R 770 /opt/scripts/

EXPOSE 10080
EXPOSE 30033
EXPOSE 9987/udp

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]