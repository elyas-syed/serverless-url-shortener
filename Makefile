.PHONY: build test validate plan clean

ROOT := $(CURDIR)

build:
	@mkdir -p dist
	@for fn in create_link redirect get_analytics click_tracker; do \
		rm -rf dist/$$fn dist/$$fn.zip; \
		mkdir -p dist/$$fn/shared; \
		cp -R $(ROOT)/src/shared/. dist/$$fn/shared/; \
		rm -rf dist/$$fn/shared/__pycache__; \
		cp $(ROOT)/src/$$fn/handler.py dist/$$fn/; \
		( cd dist/$$fn && zip -r ../$$fn.zip . > /dev/null ); \
		echo "Built dist/$$fn.zip"; \
	done

test:
	@python3 -m venv .venv 2>/dev/null || true
	@. .venv/bin/activate && pip install -q pytest && python -m pytest tests/ -v

validate: build
	cd terraform && terraform init -backend=false && terraform validate

plan: build
	cd terraform && terraform init -backend=false && terraform plan

clean:
	rm -rf dist .pytest_cache
	find src -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
