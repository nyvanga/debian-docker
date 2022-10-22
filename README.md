# Debian with Docker

Docker in docker based on Debian and deb packages (as it should be)...

Take it for a spin:
```
docker run --rm --privileged nyvanga/docker \
	docker info
```

Run hello-world, because... you have to:
```
docker run --rm --privileged nyvanga/docker \
	docker run hello-world
```

Launch as a daemon (don't know why... but you could):
```
docker run -it --rm --privileged --name test_docker_container nyvanga/docker
```

Then execute within that container:
```
docker exec -it test_docker_container \
	docker run --rm hello-world
```

Or go completely bonkers and launch another docker inside that one:
```
docker exec -it test_docker_container \
	docker run -it --rm --privileged --name test_docker_container nyvanga/docker
```

And make the madness complete...
```
docker exec -it test_docker_container \
	docker exec -it test_docker_container \
		docker run --rm hello-world
```
