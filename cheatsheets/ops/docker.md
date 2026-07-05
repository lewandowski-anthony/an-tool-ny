# Docker Cheatsheet

> A practical Docker reference for everyday container work. The commands are cross-platform (macOS, Windows, Linux), with OS-specific notes called out where useful.

---

## Images

```bash
docker build -t app:1.0 .                 # build from Dockerfile in .
docker build -t app:1.0 -f Dockerfile.prod .
docker images                              # list local images
docker pull nginx:alpine                   # pull from registry
docker push registry/app:1.0               # push to registry
docker tag app:1.0 registry/app:1.0        # retag
docker rmi app:1.0                         # remove image
docker image prune -a                      # remove unused images
docker history app:1.0                     # show layers
docker inspect app:1.0                     # full metadata
```

---

## Containers

```bash
docker run -d --name web -p 8080:80 nginx  # detached, named, port-mapped
docker run --rm -it ubuntu bash            # interactive, auto-remove
docker run -e KEY=value app                # set env var
docker run --env-file .env app             # env from file
docker run -v $(pwd):/app app              # bind mount
docker run -v data:/var/lib/app app        # named volume
docker ps                                   # running containers
docker ps -a                                # all containers
docker logs -f web                          # follow logs
docker exec -it web bash                    # shell into running container
docker stop web && docker rm web            # stop + remove
docker restart web
docker stats                                # live resource usage
```

> **Tip:** This repo's `scripts/docker/docker-clean-containers.sh` can remove all containers, volumes, and networks at once.

---

## Networks & Volumes

```bash
docker network ls
docker network create appnet
docker network connect appnet web
docker volume ls
docker volume create data
docker volume inspect data
docker volume prune                         # remove unused volumes
```

---

## Cleaning Up

```bash
docker system df                            # disk usage overview
docker system prune                         # remove stopped containers, unused nets/images
docker system prune -a --volumes            # aggressive: also volumes + all unused images
docker container prune
docker builder prune                        # clear build cache
```

> **Warning:** `--volumes` deletes named volumes, so you can lose database data. Double-check first.

---

## Docker Compose

```bash
docker compose up -d                        # start stack (detached)
docker compose up --build                   # rebuild then start
docker compose down                         # stop + remove
docker compose down -v                      # also remove volumes
docker compose ps
docker compose logs -f <service>
docker compose exec <service> bash
docker compose restart <service>
docker compose config                       # validate & render merged config
```

---

## Dockerfile Best Practices

* **Use small base images**: `alpine`, `-slim`, or distroless where possible.
* **Multi-stage builds** to keep final images lean:
  ```dockerfile
  FROM node:20 AS build
  WORKDIR /app
  COPY package*.json ./
  RUN npm ci
  COPY . .
  RUN npm run build

  FROM nginx:alpine
  COPY --from=build /app/dist /usr/share/nginx/html
  ```
* **Order layers by change frequency**: copy dependency manifests and install *before* copying source, to maximize cache hits.
* **Combine RUN steps** with `&&` and clean up in the same layer (`apt-get clean`, `rm -rf /var/lib/apt/lists/*`).
* **Use `.dockerignore`** (node_modules, .git, build artifacts) to shrink build context.
* **Don't run as root**: add a user and `USER app`.
* **Pin versions** (`nginx:1.27-alpine`, not `latest`) for reproducible builds.
* **Prefer `COPY` over `ADD`** unless you need URL/tar extraction.
* **One process per container**; use `CMD` (or `ENTRYPOINT`) with exec form: `CMD ["node", "server.js"]`.
* **Declare `HEALTHCHECK`** so orchestrators know when the container is ready.

---

## Security Tips

* Scan images for vulnerabilities — e.g. Trivy (see `scripts/docker/docker-scan-component.sh`), `docker scout cves <image>`.
* Never bake secrets into images; use build secrets (`--secret`) or runtime env/volumes.
* Use read-only filesystems where possible: `docker run --read-only`.
* Drop capabilities: `docker run --cap-drop ALL --cap-add NET_BIND_SERVICE`.
* Set resource limits: `--memory=512m --cpus=1.5`.

---

## Cross-Platform Notes

* **Install**: macOS/Windows use **Docker Desktop**; Linux uses the native Docker Engine (`apt`/`dnf`) — no Desktop needed.
* **Bind mount paths**: macOS/Linux use `/abs/path` or `$(pwd)`; Windows PowerShell uses `${PWD}` and drive paths (`C:\...`). WSL2 paths differ from Windows paths.
* **File sharing performance**: bind mounts are slower on macOS/Windows (VM boundary); prefer named volumes for heavy I/O (e.g. databases, node_modules).
* **`--network host`** works fully on Linux only; on Docker Desktop it's partially emulated.
* **Line endings**: shell scripts copied into Linux images must use LF, not CRLF (a Windows gotcha that breaks `ENTRYPOINT` scripts).

---

## Quick Reference: "How Do I…?"

| I want to…                     | Do this                                  |
|--------------------------------|------------------------------------------|
| Shell into a running container | `docker exec -it <name> bash`            |
| See why a container exited     | `docker logs <name>`                     |
| Free up disk space             | `docker system prune -a`                 |
| Rebuild a compose service      | `docker compose up -d --build <service>` |
| Inspect an image's layers      | `docker history <image>`                 |
| Copy a file out of a container | `docker cp <name>:/path ./local`         |
| Run a throwaway shell          | `docker run --rm -it alpine sh`          |

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
