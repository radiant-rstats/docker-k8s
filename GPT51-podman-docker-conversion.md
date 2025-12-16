# Plan: Multi-Platform Docker & Podman Images (No R)

## Objectives
- Produce both Docker and Podman multi-architecture (amd64/arm64) images from a single Containerfile or tightly coupled variant.
- Retain current dual entrypoints (rootful `start-container.sh`, rootless `start-rootless.sh`) and service set (Postgres, Hadoop/Spark, SSHD, pgweb).
- Remove all R/Quarto/Radiant dependencies and related tooling.
- Keep build and runtime experience close to what is documented in `PODMAN-BRANCH-SUMMARY.md` and `ROOTLESS-USAGE.md`, while simplifying the stack.

## Baseline Observations (root docs review)
- `rsm-msba-k8s/Dockerfile` already targets amd64/arm64 via buildx and sets arch-specific env vars (JAVA_HOME, pgweb binary, DOCKERHUB_NAME).
- Build orchestration exists for Docker (`Makefile`, `scripts-mp/build.sh`) but supporting scripts referenced in docs (e.g., `build-multiplatform.sh`) are missing from the repo.
- Podman rootless mode is supported via `files/start-rootless.sh`; rootful Docker remains default (`start-container.sh`).
- Heavy R footprint: env vars in Dockerfile (R_VERSION, R_HOME, QUARTO_VERSION), install scripts (`files/install-quarto.sh`, `files/install-radiant.sh`), zsh helpers referencing Radiant, and potential R content in docs and startup menus.

## Target State
- Single Containerfile (or minimal variant) that builds the same image for both Docker and Podman using the same build arguments and platform matrix.
- Build tooling that can switch between Docker and Podman engines while producing identical multi-arch manifests and tags.
- No R toolchain: remove R, Quarto, Radiant installs, R env vars, and dependent shell helpers; base image chosen to avoid pulling R layers.
- Updated documentation covering both engines, rootful/rootless usage, and the new R-free stack.

## Work Plan
1. **Inventory & Dependencies**
   - Enumerate all R-related files/scripts/config (Dockerfile envs, install scripts, zsh helpers, docs).
   - Identify any runtime references to R/Radiant in menus (`files/zsh`), startup scripts, or user onboarding.
   - Confirm non-R dependencies that must stay (Python, Hadoop/Spark, Postgres, pgweb, SSHD, oh-my-zsh, uv).

2. **Containerfile Refactor (R Removal)**
   - Choose/confirm base image without R (e.g., a Python/Jupyter image variant that omits R, or a minimal Python base plus Hadoop/Spark).
   - Strip R/Quarto env vars and install steps from `rsm-msba-k8s/Dockerfile`.
   - Remove or replace R-specific files: `files/install-quarto.sh`, `files/install-radiant.sh`, Radiant zsh scripts/aliases, and any R-specific COPY directives.
   - Validate remaining steps still work (pgweb download, Hadoop setup, uv/oh-my-zsh, Postgres config).
   - Ensure final image size is acceptable after cleanup.

3. **Podman/Docker Multi-Arch Build Unification**
   - Add/restore a single build entrypoint script (e.g., `scripts-mp/build-multiplatform.sh`) that detects engine (`docker` vs `podman`) and routes to buildx/buildah as needed.
   - Extend `Makefile` to support both engines (parameterize engine, builder name, push logic, and manifest inspection commands).
   - Define tagging scheme (version + latest) shared across engines; ensure `IMAGE_VERSION`/similar arg still available.
   - For Podman: decide between `podman buildx` (v5+) or `buildah manifest` pipeline; script accordingly.
   - Normalize log handling (reuse `build-logs/` split/tee approach) for both engines.

4. **Runtime Compatibility**
   - Re-test rootful and rootless flows with R removed: start scripts, Postgres init, Hadoop/Spark env vars, pgweb binary resolution, SSHD permissions.
   - Verify no startup scripts reference removed R binaries or env vars.
   - Confirm user environment (.bashrc/.zshrc) updates still apply to rootless mode.

5. **Documentation & DX**
   - Update `PODMAN-BRANCH-SUMMARY.md` and `ROOTLESS-USAGE.md` to reflect new build paths, engine support, and R removal.
   - Add/refresh `rsm-msba-k8s/README.md` to document the new build script(s) and base image change.
   - Provide short “migration” notes for users expecting R (call out removal and alternatives, if any).
   - Include example commands for both Docker and Podman multi-arch builds and pulls.

6. **Validation & Release**
   - Smoke-test images on both platforms (amd64/arm64) and both engines (Docker Desktop, Podman rootless on Linux).
   - Inspect manifests to confirm both architectures are present.
   - Tag/push to registry once validated; optionally maintain a temporary `-no-r` tag for transition.

## Open Questions
1. Which base image should we target post-R removal (stay on `quay.io/jupyter/pyspark-notebook` or move to a leaner Python/Spark base)?
2. What registry/tag namespace should the unified images use (keep `vnijs/rsm-msba-k8s` or move to a new repo/tag to signal R removal)?
3. Should Podman builds rely on `podman buildx` (Docker-compatible) or a buildah-native workflow?
4. Are there any remaining R-dependent user workflows that need a documented alternative before removal?
