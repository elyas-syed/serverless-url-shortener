# Development

## Prerequisites

- Python 3.12+
- `make`, `zip`
- Terraform >= 1.10 (for `validate` / `plan` targets)

AWS credentials are only required for `terraform apply` and live integration testing.

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
└── assets/
tests/
scripts/demo.sh
terraform/
```

## Make targets

| Target | Description |
|--------|-------------|
| `make build` | Package all Lambdas to `dist/*.zip` |
| `make test` | Run pytest in a local venv |
| `make validate` | Build + `terraform validate` |
| `make plan` | Build + `terraform plan` |
| `make clean` | Remove `dist/`, caches |

### Build process

`make build` copies `src/shared/` and each handler into `dist/{function}/`, then zips the directory. Each Lambda is self-contained — there is no shared layer.

**Gotcha:** The Makefile runs `zip` inside a subshell `( cd dist/$$fn && zip ...)` so the zip root contains `handler.py` and `shared/`, not the parent folder name.

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

Runs `terraform init -backend=false` and `terraform validate` in `terraform/`.

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
