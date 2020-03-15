FROM java:8
FROM hotswapagent/hotswap-vm
MAINTAINER Maxwell Phillips "max@maxphillipsdev.com"

# Install gpg
RUN  apk add gnupg 

ENV GOSU_VERSION 1.11
RUN set -eux; \
	\
	apk add --no-cache --virtual .gosu-deps \
		ca-certificates \
		dpkg \
		gnupg \
	; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
# clean up fetch dependencies
	apk del --no-network .gosu-deps; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true

# Add a minecraft user cause running minecraft as root is big no no
RUN addgroup --gid 1000 minecraft && \
    adduser --ingroup minecraft --uid 1000 --system --no-create-home minecraft && \
    touch /run/first_time && \
    mkdir -p /opt/minecraft /var/lib/minecraft /usr/src/minecraft && \
    echo "set -g status off" > /root/.tmux.conf

COPY spigot /usr/local/bin/
ONBUILD COPY . /usr/src/minecraft

EXPOSE 25565
EXPOSE 5005

VOLUME ["/opt/minecraft", "/var/lib/minecraft"]

ENTRYPOINT ["/usr/local/bin/spigot"]
CMD ["run"]
