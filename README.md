# Gogs via Docker

## Concept

* nginx reverse proxy (in docker container), automatically configured (except for the ssl certificates)
* backend gogs instance (in docker container)

## Getting the images

Just pull them:
```sh
docker pull hasufell/alpine-gogs
docker pull hasufell/alpine-nginx-proxy
```

## Configuration

Gogs is configured via the web interface once the instance has started.

In addition, the following environment variables can be passed via `-e` to
`docker run`:
* `VIRTUAL_HOST`: sets the hostname for connecting to the gogs backend server
* `VIRTUAL_PORT`: tells the front proxy on which port to contact the backend server
* `GOGS_SSH_PORT`: this only changes the port of the sshd service, you will still have to adjust it in the web configuration interface (optional, default 22)

### Certificates

We need certificates which are named according to the hostname
of the gogs instance (e.g. if you will access gogs via
`https://gogs.foo.com`, then you name your certificates files
`gogs.foo.crt` and `gogs.foo.key`).

Just drop these in a directory. We will mount this directory into the
container later.

## Running for the first time

Create the volumes. This will create a persistent data volume container.
You should not remove it (keep in mind that this container is not running).
```sh
docker run \
	--name=gogs-volumes \
	-v /data \
	hasufell/alpine-gogs \
	echo gogs-volumes
```

Now we start the front proxy.
```sh
docker run -ti -d \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	-v <full-path-to-nginx-certs>:/etc/nginx/certs \
	-p 80:80 \
	-p 443:443 \
	hasufell/alpine-nginx-proxy
```

Now we can start the gogs instance.

```sh
docker run -ti -d \
	--volumes-from gogs-volumes \
	--name=gogs \
	-e VIRTUAL_HOST=<hostname> \
	-e VIRTUAL_PORT=3000 \
	-e GOGS_SSH_PORT=<ssh-port> \
	-p <sshport>:<sshport> \
	hasufell/alpine-gogs
```

Note that `VIRTUAL_HOST` and `VIRTUAL_PORT` are __strictly__ necessary,
because they are used by the front proxy to update its configuration
automatically.

## Initial web configuration

Make sure:
* `Database Type` is SQLite3
* `Domain` is set to your domain
* `SSH Port` is set to what you specified in `GOGS_SSH_PORT` (or 22 for default)
* `Application URL` is `https://<domain>/` (not `http`) _without_ the Port 3000

## Update procedure
```sh
docker stop gogs
docker rm gogs
docker pull hasufell/alpine-gogs
docker run -ti -d \
	--volumes-from gogs-volumes \
	--name=gogs \
	-e VIRTUAL_HOST=<hostname> \
	-e VIRTUAL_PORT=3000 \
	-e GOGS_SSH_PORT=<ssh-port> \
	-p <sshport>:<sshport> \
	hasufell/alpine-gogs
```
