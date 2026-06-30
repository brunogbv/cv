# CI/CD

CI is automated and lint-only. Deployment (CD) is **manual** — there is no pipeline that ships the
site; a human runs `make` targets on the host that serves [valerio.dev](https://valerio.dev).

## Continuous Integration — GitHub Actions

One workflow: **`.github/workflows/superlinter.yml`** (name: `Lint`).

- **Triggers:** every `push` and every `pull_request`.
- **Runner:** `ubuntu-latest`.
- **Steps:**
  1. Checkout with `fetch-depth: 0` — Super-Linter needs full git history to diff changed files.
  2. Load `config/lint/super-linter.env` into `$GITHUB_ENV`.
  3. Run `super-linter/super-linter@v6.7.0`, reporting results as GitHub status checks
     (`permissions: statuses: write`, using the default `GITHUB_TOKEN`).
- A Super-Linter status badge is shown at the top of the root [`README.md`](../README.md).

There are **no automated tests** and **no build/deploy** in CI — linting is the only gate.

### Linter configuration

Defined in `config/lint/super-linter.env`:

| Setting                          | Value / effect                                                  |
| -------------------------------- | --------------------------------------------------------------- |
| `DEFAULT_BRANCH`                 | `main`                                                          |
| `FILTER_REGEX_EXCLUDE`           | `.src/templates/*` — Handlebars templates are not linted.       |
| `IGNORE_GITIGNORED_FILES`        | `true`                                                          |
| `LINTER_RULES_PATH`              | `config/lint`                                                   |
| Enabled validators               | CSS, Dockerfile (hadolint), GitHub Actions, HTML, JavaScript (`standard`), JSON, JSX, Markdown, TypeScript (`standard`), XML, YAML |

JavaScript is checked against the **`standard`** style; CSS uses `stylelint` with
`stylelint-config-standard` (declared in `package.json`).

### Running CI locally

```sh
make lint
```

This runs the same Super-Linter image in Docker with `RUN_LOCAL=true`, using
`config/lint/super-linter.env`, so you can reproduce CI results before pushing.

## Continuous Deployment — manual, Docker-based

The site is self-hosted. Deployment is orchestrated by the `Makefile` and `docker-compose.yml`,
which define three services sharing two named volumes:

| Service           | Role                                                                 |
| ----------------- | -------------------------------------------------------------------- |
| `app-builder`     | Builds the site (the `Dockerfile` builder image) into the `html` volume. |
| `webserver`       | nginx serving the `html` volume on ports 80/443 (`config/nginx/`).   |
| `certbot` / `certbot-dry-run` | Issues Let's Encrypt certs for `valerio.dev` + `www.valerio.dev` into the `certs` volume. |

| Volume  | Purpose                                                              |
| ------- | ------------------------------------------------------------------- |
| `html`  | The built static site, shared by `app-builder`, `webserver`, `certbot`. |
| `certs` | `/etc/letsencrypt` — TLS certificates.                              |

### Deploy commands

```sh
make build                      # Build the site into the html volume (via app-builder)
make webserver                  # Start nginx (HTTP only)
make webserver-upgrade-to-https # Issue certs, swap to SSL config, reload nginx
make all                        # First-time only: build + serve + HTTPS (recreates certs!)
```

- `make all` is for a **first-time** stand-up. Avoid it for routine content updates because it
  recreates certificates.
- For a routine content update: `make build` to rebuild, then redeploy/reload the webserver.

### TLS / certbot

- `make certificates` runs certbot for real; `make certificates-dry-run` simulates issuance.
- **Let's Encrypt has strict rate limits.** Always validate with `make certificates-dry-run`
  before `make certificates` / `make webserver-upgrade-to-https`, or you can be temporarily
  blocked from issuing certs.
- `make webserver-upgrade-to-https` runs certbot, swaps nginx to the SSL site config
  (`valerio-ssl.conf`), and reloads nginx (`webserver-ssl-config` + `webserver-restart-nginx`).

### nginx configuration

The webserver image (`config/nginx/Dockerfile`, `nginx:alpine`) selects which site config to
enable via the `SITE_NAME` build arg, symlinking it into `sites-enabled/`. Three configs live in
`config/nginx/sites-available/`:

| Config               | Behavior                                                                                  |
| -------------------- | ----------------------------------------------------------------------------------------- |
| `valerio.dev`        | HTTP-only (pre-TLS). Serves the ACME challenge path and `/healthcheck`; `/` returns 404.  |
| `valerio-ssl.conf`   | Redirects HTTP → HTTPS; serves the site over 443 using the Let's Encrypt cert/key.        |
| `valerio-local.conf` | Same as `valerio.dev` but also matches `localhost`, for local testing.                    |

All variants expose `/healthcheck` (also used by the `webserver` healthcheck in
`docker-compose.yml`). The ACME challenge location is what lets certbot validate the domain over
HTTP before certs exist.

### Deployment flow

```text
make build ─▶ html volume ─▶ webserver (nginx :80, valerio.dev config, /healthcheck)
                                   │
                   make webserver-upgrade-to-https
                                   │
                   certbot (ACME challenge via :80) ─▶ certs volume
                                   │
                   swap to valerio-ssl.conf + reload ─▶ nginx :443 (HTTPS)
```

### Helpful operational targets

```sh
make logs-webserver       # nginx logs
make logs-app-builder     # build logs
make logs-certbot         # certbot logs
make down                 # stop the webserver (docker compose down)
make dev-build            # dockerized build, copied back into local ./dist
```
