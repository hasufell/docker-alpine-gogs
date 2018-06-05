FROM       alpine:3.7
MAINTAINER Julian Ospald <hasufell@posteo.de>


ENV GOPATH /gopath
ENV PATH $PATH:$GOROOT/bin:$GOPATH/bin

WORKDIR /gopath/src/github.com/gogs/gogs/

RUN apk --no-cache add \
		bash \
		ca-certificates \
		curl \
		git \
		go \
		linux-pam \
		openssh \
		redis \
		shadow \
		socat \
		sqlite \
		sudo \
		supervisor \
		tzdata \
		&& \
	apk --no-cache add --virtual build-deps \
		build-base \
		linux-pam-dev \
		&& \
	git clone --depth=1 https://github.com/gogs/gogs.git \
		/gopath/src/github.com/gogs/gogs && \
	make build TAGS="sqlite redis memcache cert pam" && \
	apk del build-deps && \
	mkdir /app/ && \
	mv /gopath/src/github.com/gogs/gogs/ /app/gogs/ && \
	rm -rf "$GOPATH" /var/cache/apk/*

RUN adduser -G git -H -D -g 'Gogs Git User' git -h /data/git -s /bin/bash && \
	usermod -p '*' git && passwd -u git

WORKDIR /app/gogs/

# SSH login fix, otherwise user is kicked off after login
RUN echo "export VISIBLE=now" >> /etc/profile && \
	echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

# Setup ssh
COPY config/sshd_config /etc/ssh/sshd_config

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
