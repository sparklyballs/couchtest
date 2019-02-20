ARG ALPINE_VER="3.9"
FROM alpine:${ALPINE_VER} as fetch-stage

############## fetch stage ##############

# package versions
ARG COUCHP_BRANCH="develop"

# install fetch packages
RUN \
	apk add --no-cache \
		bash \
		curl \
		jq

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# fetch source code
RUN \
	set -ex \
	&& mkdir -p \
		/app/couchpotato \
	&& COUCHP_RAW_COMMIT=$(curl -sX GET "https://api.github.com/repos/CouchPotato/CouchPotatoServer/commits/${COUCHP_BRANCH}" \
		| jq -r '.sha') \
	&& COUCHP_COMMIT="${COUCHP_RAW_COMMIT:0:7}" \
	&& curl -o \
	/tmp/couchpotato.tar.gz -L \
	"https://github.com/CouchPotato/CouchPotatoServer/archive/${COUCHP_COMMIT}.tar.gz" \
	&& tar xf \
	/tmp/couchpotato.tar.gz -C \
	/app/couchpotato --strip-components=1

FROM sparklyballs/alpine-test:${ALPINE_VER}

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
