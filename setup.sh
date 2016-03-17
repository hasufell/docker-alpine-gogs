#!/bin/bash

if [[ ! -d /data/gogs ]] ; then
	mkdir -p /var/run/sshd
	mkdir -p /data/gogs/data /data/gogs/conf /data/gogs/log /data/git /data/gogs/custom
fi

if [[ ! -d /data/ssh ]] ; then
	mkdir /data/ssh
	ssh-keygen -q -f /data/ssh/ssh_host_rsa_key -N '' -t rsa
	ssh-keygen -q -f /data/ssh/ssh_host_dsa_key -N '' -t dsa
	ssh-keygen -q -f /data/ssh/ssh_host_ed25519_key -N '' -t ed25519
	chown -R root:root /data/ssh/*
	chmod 600 /data/ssh/*
fi

ln -sf /data/gogs/custom ./custom
ln -sf /data/gogs/log ./log
ln -sf /data/gogs/data ./data
ln -sf /data/git /home/git


if [[ ! -d ~git/.ssh ]] ; then
  mkdir ~git/.ssh
  chmod 700 ~git/.ssh
fi

if [[ ! -f ~git/.ssh/environment ]] ; then
  echo "GOGS_CUSTOM=/data/gogs" > ~git/.ssh/environment
  chown git:git ~git/.ssh/environment
  chown 600 ~git/.ssh/environment
fi

chown -R git:git /data .

if [[ ${GOGS_SSH_PORT} ]] ; then
	echo "Port ${GOGS_SSH_PORT}" >> /etc/ssh/sshd_config
fi
