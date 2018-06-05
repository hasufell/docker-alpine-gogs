FROM       alpine:3.7
MAINTAINER Julian Ospald <hasufell@posteo.de>


ENV GOPATH /gopath
ENV PATH $PATH:$GOROOT/bin:$GOPATH/bin

WORKDIR /gopath/src/github.com/gogs/gogs/

RUN apk --no-cache add go redis sqlite openssh sudo supervisor git \
		bash linux-pam build-base linux-pam-dev shadow && \
	git clone --depth=1 https://github.com/gogs/gogs.git \
		/gopath/src/github.com/gogs/gogs && \
	go get -v -tags "sqlite redis memcache cert pam" && \
	go build -tags "sqlite redis memcache cert pam" && \
	mkdir /app/ && \
	mv /gopath/src/github.com/gogs/gogs/ /app/gogs/ && \
	useradd --shell /bin/bash --system --comment gogs git && \
	apk --no-cache del build-base linux-pam-dev shadow && \
	rm -rf "$GOPATH" /var/cache/apk/*


WORKDIR /app/gogs/

# SSH login fix, otherwise user is kicked off after login
RUN echo "export VISIBLE=now" >> /etc/profile && \
	echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

# Setup server keys on startup
RUN echo "HostKey /data/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config && \
	echo "HostKey /data/ssh/ssh_host_dsa_key" >> /etc/ssh/sshd_config && \
	echo "HostKey /data/ssh/ssh_host_ed25519_key" >> /etc/ssh/sshd_config

# Prepare data
ENV GOGS_CUSTOM /data/gogs
RUN echo "export GOGS_CUSTOM=/data/gogs" >> /etc/profile

RUN chown -R redis /var/log/redis
RUN sed -i -e 's/daemonize yes/daemonize no/' /etc/redis.conf

COPY setup.sh /setup.sh
RUN chmod +x /setup.sh
COPY config/supervisord.conf /etc/supervisord.conf

EXPOSE 3000

CMD /setup.sh && exec /usr/bin/supervisord -n -c /etc/supervisord.conf
