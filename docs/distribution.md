# Distribution & Deployment

This project uses Docker to create a secure, minimal, and highly optimized container for distribution.

## Multi-stage Dockerfile

The `Dockerfile` inside `newsfeed/docker/` uses a multi-stage approach to separate the build environment from the runtime environment.

### Stage 1: Builder
- **Base Image**: `rust:1.85-slim-bookworm`
- **Purpose**: Compiles the Rust application and its dependencies into a statically linked release binary.
- **Process**: Uses the workspace manifest to build the `newsfeed-server` binary with `--release`.

### Stage 2: Runtime
- **Base Image**: `debian:bookworm-slim`
- **Purpose**: A minimal environment containing only what is necessary to run the binary (such as SSL root certificates for database TLS connections).
- **Security**: The image creates and uses a non-root user (`newsfeed`) to run the application securely.

## Building the Container

You can build the Docker container manually or use `docker-compose`. 

### Using Docker Compose

The simplest way to build and run the application locally in an isolated network is using Docker Compose:

```bash
cargo make docker-up
```
This shortcut will mount the `.env` file automatically and map port `4815` to your host machine. You can tear it down later using `cargo make docker-down`.

### Manual Docker Build

If you are building the image for a registry or remote deployment, run the build from the project root:

```bash
docker build -t newsfeed-service:latest -f newsfeed/docker/Dockerfile .
```

To run the standalone container with your `.env` file:

```bash
docker run -p 4815:4815 --env-file .env newsfeed-service:latest
```

Once the container is running, the OpenAPI interactive documentation is available at `http://localhost:4815/swagger-ui`.

## Production Considerations

- **Reverse Proxy**: While Axum is robust, it's generally recommended to place a reverse proxy (like Nginx, Traefik, or an AWS Application Load Balancer) in front of the container for SSL termination and distributed DDoS protection.
- **Environment Variables**: In production, do not mount the `.env` file. Instead, inject the environment variables natively through your orchestration platform (e.g., Kubernetes ConfigMaps/Secrets, AWS ECS Task Definitions, or Docker Swarm Secrets).

## GitHub Releases

We use GitHub Actions to automatically build and bundle compiled binaries for Linux, macOS, and Windows. 

To trigger a new release build for the `newsfeed` service, you must commit your version bumps and push a specific Git tag. Follow this exact sequence in your terminal:

**1. Stage and commit your changes:**
```bash
git add .
git commit -m "chore: bump version to 2.0.0"
```

**2. Create the Git tag:**
Use the `newsfeed-v*` prefix convention to ensure the monorepo only builds the newsfeed project.
```bash
git tag newsfeed-v2.0.0
```

**3. Push the commit to GitHub:**
```bash
git push origin main
```
*(This pushes the code changes and triggers the standard `newsfeed-ci.yml` testing pipeline).*

**4. Push the tag to GitHub:**
```bash
git push origin newsfeed-v2.0.0
```
*(This pushes the tag, which instantly triggers the `newsfeed-release.yml` pipeline).*

The automated pipeline will compile the binary in release mode, bundle it with `.env.example`, `README.md`, and `LICENSE` in a `.tar.gz` (or `.zip` for Windows) archive, and publish it as a GitHub Release.

### Retriggering a Failed Release

If a release build fails or you need to update a tag with a hotfix, you can delete and recreate the tag to retrigger the pipeline.

**1. Fix your code and commit the changes:**
```bash
git add .
git commit -m "fix: address release build failure"
```

**2. Delete the old failing tag (locally and on GitHub):**
```bash
git tag -d newsfeed-v2.0.0
git push origin --delete newsfeed-v2.0.0
```

**3. Create the tag again on your new commit and push it:**
```bash
git tag newsfeed-v2.0.0
git push origin newsfeed-v2.0.0
```
