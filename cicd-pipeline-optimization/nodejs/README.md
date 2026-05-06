# Optimize CI 

#### Enable BuildKit 
```bash
# Install for root user:
mkdir -p ~/.docker/cli-plugins/
curl -L -o ~/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v0.14.0/buildx-v0.14.0.linux-amd64 
chmod +x ~/.docker/cli-plugins/docker-buildx

# Install for system wide:
sudo mkdir -p /usr/lib/docker/cli-plugins
sudo cp ~/.docker/cli-plugins/docker-buildx /usr/lib/docker/cli-plugins/
sudo chmod +x /usr/lib/docker/cli-plugins/docker-buildx

# Check:
docker buildx version

# Create bootstrap
docker buildx create \
  --name mybuilder \
  --driver docker-container \
  --bootstrap \
  --use

# Enable:
export DOCKER_BUILDKIT=1
```

### 1. Multistage Build and small size base image
```bash
# --- STAGE 1: Build Stage ---
FROM node:20.11.1-bookworm AS builder

WORKDIR /app

# Copy package files to reuse Docker Layer Cache for node_modules
COPY package*.json ./

# Install dependencies (include build-essential and C++ lib)
RUN npm install

# --- STAGE 2: Runtime Stage ---
FROM node:20.11.1-bookworm-slim

WORKDIR /app

## Copy node_modules from stage builder
COPY --from=builder /app/node_modules ./node_modules
COPY . .

EXPOSE 3000

CMD ["node", "app.js"]
```

### 2. Docker Layer Caching 
#### First build:
```bash
 docker build -t peidhhn/nodejs-app:v1 .

[+] Building 27.6s (15/15) FINISHED                                                                                        docker:default
 => [internal] load build definition from Dockerfile                                                                                 0.0s
 => => transferring dockerfile: 546B                                                                                                 0.0s
 => [internal] load metadata for docker.io/library/node:20.11.1-bookworm-slim                                                        3.9s
 => [internal] load metadata for docker.io/library/node:20.11.1-bookworm                                                             0.0s
 => [auth] library/node:pull token for registry-1.docker.io                                                                          0.0s
 => [internal] load .dockerignore                                                                                                    0.0s
 => => transferring context: 91B                                                                                                     0.0s
 => [builder 1/4] FROM docker.io/library/node:20.11.1-bookworm                                                                       0.3s
 => [stage-1 1/4] FROM docker.io/library/node:20.11.1-bookworm-slim@sha256:357deca6eb61149534d32faaf5e4b2e4fa3549c2be610ee1019bf34  16.3s
    ....
 => [internal] load build context                                                                                                    1.8s
 => => transferring context: 37.86MB                                                                                                 1.8s
 => [builder 2/4] WORKDIR /app                                                                                                       0.1s
 => [builder 3/4] COPY package*.json ./                                                                                              0.2s
 => [builder 4/4] RUN npm install                                                                                                   15.0s
 => [stage-1 2/4] WORKDIR /app                                                                                                       0.2s
 => [stage-1 3/4] COPY --from=builder /app/node_modules ./node_modules                                                               0.9s
 => [stae-1 4/4] COPY . .                                                                                                           2.7s
    ...
```
#Note:  => [builder 4/4] RUN npm install:	15.0s (Total: 27.6s include pull image node:20.11.1-bookworm)
```
#### Second build:
```bash
# Edit some code but not change any dependencies
echo "//Edit some code"  >> app.js

# Build again:

docker build -t peidhhn/nodejs-app:v2 .
[+] Building 4.7s (15/15) FINISHED                                                                                         docker:default
 => [internal] load build definition from Dockerfile                                                                                 0.0s
 => => transferring dockerfile: 546B                                                                                                 0.0s
 => [internal] load metadata for docker.io/library/node:20.11.1-bookworm                                                             0.0s
 => [internal] load metadata for docker.io/library/node:20.11.1-bookworm-slim                                                        2.0s
 => [auth] library/node:pull token for registry-1.docker.io                                                                          0.0s
 => [internal] load .dockerignore                                                                                                    0.0s
 => => transferring context: 91B                                                                                                     0.0s
 => [builder 1/4] FROM docker.io/library/node:20.11.1-bookworm                                                                       0.0s
 => [internal] load build context                                                                                                    0.8s
 => => transferring context: 513.13kB                                                                                                0.7s
 => [stage-1 1/4] FROM docker.io/library/node:20.11.1-bookworm-slim@sha256:357deca6eb61149534d32faaf5e4b2e4fa3549c2be610ee1019bf340  0.0s
 => CACHED [stage-1 2/4] WORKDIR /app                                                                                                0.0s
 => CACHED [builder 2/4] WORKDIR /app                                                                                                0.0s
 => CACHED [builder 3/4] COPY package*.json ./                                                                                       0.0s
 => CACHED [builder 4/4] RUN npm install                                                                                             0.0s
 => CACHED [stage-1 3/4] COPY --from=builder /app/node_modules ./node_modules                                                        0.0s
 => [stage-1 4/4] COPY . .                                                                                                           1.1s
    ...

#Note:  => CACHED [builder 4/4] RUN npm install:       0.0s (Total: 4.7s include Reuse BaseImage and LAYER CACHE)
```

### 3. Use BuildKit plugin with cache-from/cache-to

```bash
docker buildx build -t peidhhn/nodejs-app:v1 --cache-from type=registry,ref=peidhhn/nodejs-app:buildcache --cache-to type=registry,ref=peidhhn/nodejs-app:buildcache,mode=max --push .
[+] Building 8.6s (17/17) FINISHED                                                                             docker-container:mybuilder
 => [internal] load build definition from Dockerfile                                                                                 0.0s
 => => transferring dockerfile: 546B                                                                                                 0.0s
 => [internal] load metadata for docker.io/library/node:20.11.1-bookworm-slim                                                        0.9s
 => [internal] load metadata for docker.io/library/node:20.11.1-bookworm                                                             0.9s
 => [internal] load .dockerignore                                                                                                    0.0s
 => => transferring context: 92B                                                                                                     0.0s
 => ERROR importing cache manifest from peidhhn/nodejs-app:buildcache                                                                0.8s
 => [builder 1/4] FROM docker.io/library/node:20.11.1-bookworm@sha256:e06aae17c40c7a6b5296ca6f942a02e6737ae61bbbf3e2158624bb0f88799  0.0s
 => => resolve docker.io/library/node:20.11.1-bookworm@sha256:e06aae17c40c7a6b5296ca6f942a02e6737ae61bbbf3e2158624bb0f887991b5       0.0s
 => [internal] load build context                                                                                                    0.0s
 => => transferring context: 220B                                                                                                    0.0s
 => [stage-1 1/4] FROM docker.io/library/node:20.11.1-bookworm-slim@sha256:357deca6eb61149534d32faaf5e4b2e4fa3549c2be610ee1019bf340  0.0s
 => => resolve docker.io/library/node:20.11.1-bookworm-slim@sha256:357deca6eb61149534d32faaf5e4b2e4fa3549c2be610ee1019bf340ea8c51ec  0.0s
 => CACHED [stage-1 2/4] WORKDIR /app                                                                                                0.0s
 => CACHED [builder 2/4] WORKDIR /app                                                                                                0.0s
 => CACHED [builder 3/4] COPY package*.json ./                                                                                       0.0s
 => CACHED [builder 4/4] RUN npm install                                                                                             0.0s
 => CACHED [stage-1 3/4] COPY --from=builder /app/node_modules ./node_modules                                                        0.0s
 => CACHED [stage-1 4/4] COPY . .                                                                                                    0.0s
 => exporting to image                                                                                                               6.8s
 => => exporting layers                                                                                                              0.0s
 => => exporting manifest sha256:dc22c34bf4a4f95289fbc5c185a0c1de4bb9e289c7d838772017e0cdee93c47b                                    0.0s
 => => exporting config sha256:5e1765c80fe615dfa346d6121c31ac06d91e20208f09b925dbc89280cdd491a6                                      0.0s
 => => exporting attestation manifest sha256:23faa75697463f2753954bf7daf3c1d3729b4867ac66149c7b22016d75234873                        0.0s
 => => exporting manifest list sha256:c5fda27e807ff50eb348c80b7616d87439fdadd1084e7091dcf3c139ff315c6a                               0.0s
 => => pushing layers                                                                                                                3.8s
 => => pushing manifest for docker.io/peidhhn/nodejs-app:v1@sha256:c5fda27e807ff50eb348c80b7616d87439fdadd1084e7091dcf3c139ff315c6a  2.9s
 => exporting cache to registry                                                                                                      5.7s
 => => preparing build cache for export                                                                                              0.0s
 => => sending cache export                                                                                                          5.7s
 => => writing layer sha256:503fbb4f74dfc223fa7df9ea3a583f85ae96f7c16c55b77d692ffa77d56a8b30                                         2.3s
    ...
 => => writing config sha256:642447fda91facdfa98de89757859d6e7215732aa80bea8ef7a7efd845a233b6                                        0.3s
 => => writing cache image manifest sha256:e06a71d8eb935b6d4e058706d7a67b1e8a73dca6669a4b00269f5e90b8fe19bb                          2.1s
 => [auth] peidhhn/nodejs-app:pull,push token for registry-1.docker.io                                                               0.0s
------
 > importing cache manifest from peidhhn/nodejs-app:buildcache
------

```

### 4. Unit Test

```bash
docker run --rm -v "$PWD":/app node:20.11.1-bookworm npm test

> nodejs-devops-demo@1.0.0 test
> jest --verbose

PASS ./logic.test.js
  Test hash passwd func
    ✓ Case 1: Hash success with valid passwd (87 ms)
    ✓ Case 2: Throw error if passwd is short (5 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.57 s
Ran all test suites.
```

### 5. Scan fs and image with Trivy Scan 
```bash
trivy fs:	secret, misconfig, dependency CVE
- Secret (hardcode passwd, API key, token, ...)
- Missconfig (Dockerfile run user root, use latest tag, no resource limit on K8s, ...)
- dependencies CVE (package.json and package-lock.json)

trivy image:	OS CVE, dependency, secret, layer
- OS CVE (openssl, libc, apt packages, ...)
- Secret (copy .git/.env -> expose secret)
- Layer (copy Dockerfile -> expose layer and secret)

# Scan fs with Trivy
docker run --rm -v "$PWD:/project" -w /project aquasec/trivy:0.50.1 fs --skip-dirs node_modules --scanners secret,misconfig,vuln /project


# Scan image with Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.50.1 image peidhhn/nodejs-app:v1
```
