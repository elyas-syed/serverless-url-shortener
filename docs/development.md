# Development

## Prerequisites

- Python 3.12+
- `make`, `zip`
- Terraform >= 1.10 (for `validate` / `plan` targets)

AWS credentials are only required for `terraform apply`, `make apply` / `make destroy`, bootstrap targets, and live integration testing.

## Project layout

```
src/
├── create_link/handler.py
├── redirect/handler.py
├── get_analytics/handler.py
├── click_tracker/handler.py
└── shared/              # Copied into each Lambda zip
    ├── config.py
    ├── validation.py
    ├── rate_limit.py
    └── responses.py
web/
├── index.html
└── assets/              # CSS, JS, vendored qrcode.min.js
tests/
scripts/
├── demo.sh
└── dev-server.py        # Local UI + mock API
terraform/
```

## Make targets

| Target | Description |
|--------|-------------|
| `make serve` | Local UI + mock API (for frontend / QR UI work) |
| `make build` | Package all Lambdas to `dist/*.zip` |
| `make test` | Run pytest in a local venv |
| `make validate` | Build + `terraform validate` (no remote backend) |
| `make plan` | Build + `terraform plan` (no remote backend) |
| `make apply` | Build + interactive `terraform apply` (app stack) |
| `make destroy` | Interactive destroy of the **app** stack only |
| `make bootstrap` | Create state bucket; write gitignored `backend.hcl` |
| `make infra-destroy` | Destroy bootstrap state bucket (app stack must be gone first) |
| `make clean` | Remove `dist/`, caches |

**Naming note:** Teardown of the state bucket is `make infra-destroy` (not `make bootstrap destroy`, which would run `bootstrap` then app `destroy`).

### Build process

`make build` copies `src/shared/` and each handler into `dist/{function}/`, then zips the directory. Each Lambda is self-contained — there is no shared layer.

**Gotcha:** The Makefile runs `zip` inside a subshell `( cd dist/$$fn && zip ...)` so the zip root contains `handler.py` and `shared/`, not the parent folder name.

## Local frontend (QR UI)

`python3 -m http.server` alone will fail on `POST /api/links` (no API). Use:

```bash
make serve
```

Then open `http://127.0.0.1:8080`. The mock API supports create + get metadata so you can exercise the shorten result panel and QR download. It does **not** implement `GET /{slug}` redirects — scanning a local QR will not resolve until you use a deployed `app_url`.

QR codes are generated entirely in the browser from `short_url` (vendored `web/assets/qrcode.min.js`). No Lambda or API changes are required for QR.

## Running tests

```bash
make test
```

Tests live in `tests/` and cover validation logic (`test_validation.py`) without requiring AWS.

To run manually:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pytest
python -m pytest tests/ -v
```

## Local validation

```bash
make validate
```

Runs a fresh local `terraform init -backend=false` (clears `.terraform` so a deleted remote state bucket cannot break validate) and `terraform validate` in `terraform/`.

## Code conventions

- Python 3.12 type hints (`dict[str, Any]`, `str | None`)
- Lambda handlers named `handler` in `handler.py`
- Shared logic in `src/shared/` — copied at build time, not imported as a package
- Terraform modules are flat (no nested submodules)

## Git workflow

Use feature branches and pull requests:

```bash
git checkout -b feat/my-change
# make changes
make test
make validate
git add ...
git commit -m "feat: description"
git push -u origin feat/my-change
gh pr create --base main --head feat/my-change
```

For small doc-only or local config changes the maintainer may push directly to `main`.

## What is not covered by unit tests

- Live DynamoDB / SQS interactions
- API Gateway event shape edge cases
- CloudFront routing
- End-to-end redirect flow
- Browser QR rendering (manual / local `make serve`)

Use `scripts/demo.sh` against a deployed environment for integration verification.

## Adding validation rules

Edit `src/shared/validation.py`, add tests in `tests/test_validation.py`, then:

```bash
make test && make build && terraform apply
```

## Documentation

- Public docs: `docs/` (this folder)
- Personal drafts: `docs-local/` (gitignored)

When adding features, update the relevant doc page and [Roadmap](roadmap.md) if applicable.
