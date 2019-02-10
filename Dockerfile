ARG ALPINE_VER="3.9"
FROM alpine:${ALPINE_VER} as fetch-stage

############## fetch stage ##############

# install fetch packages
RUN \
	apk add --no-cache \
		bash \
		curl

# set shell
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# fetch source code
RUN \
	set -ex \
	&& mkdir -p \
		/app/couchpotato \
	&& COUCHPOTATO_RELEASE=$(curl -sX GET "https://api.github.com/repos/CouchPotato/CouchPotatoServer/commits/master" \
		| awk '/sha/{print $4;exit}' FS='[""]') || : \
	&& curl -o \
	/tmp/couchpotato.tar.gz -L \
	"https://github.com/CouchPotato/CouchPotatoServer/archive/${COUCHPOTATO_RELEASE}.tar.gz" \
	&& tar xf \
	/tmp/couchpotato.tar.gz -C \
	/app/couchpotato --strip-components=1

FROM lsiobase/alpine:${ALPINE_VER}

############## runtine stage ##############

# set python to use utf-8 rather than ascii.
ENV PYTHONIOENCODING="UTF-8"

# install runtime packages
RUN \
	apk add --no-cache \
		python \
		py2-lxml \
		py2-openssl

# add artifacts from fetch stage
COPY --from=fetch-stage /app/couchpotato /app/couchpotato

# add local files
COPY root/ /

# ports and volumes
EXPOSE 5050
WORKDIR /app/couchpotato
VOLUME /config /downloads /movies
