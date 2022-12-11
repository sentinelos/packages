# Packages 👋

![Dependency Diagram](deps.png)

This repository produces a set of packages that can be used to build a rootfs suitable for creating custom Linux distributions.
The packages are published as a container image, and can be "installed" by simply copying the contents to your rootfs.
For example, using Containerfile, we can do the following:

```docker
FROM scratch
COPY --from=ghcr.io/sentinelos/<pkg>:<tag> / /
```
