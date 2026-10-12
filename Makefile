.PHONY: build test validate plan apply infra-destroy bootstrap-apply bootstrap-destroy clean serve

ROOT := $(CURDIR)

serve:
	@python3 $(ROOT)/scripts/dev-server.py

bootstrap-apply:
	@test -f $(ROOT)/terraform/bootstrap/terraform.tfvars || \
		cp $(ROOT)/terraform/bootstrap/terraform.tfvars.example $(ROOT)/terraform/bootstrap/terraform.tfvars
	cd $(ROOT)/terraform/bootstrap && terraform init && terraform apply
	@BUCKET=$$(cd $(ROOT)/terraform/bootstrap && terraform output -raw state_bucket_name) && \
		printf 'bucket = "%s"\n' "$$BUCKET" > $(ROOT)/terraform/backend.hcl && \
		echo "Wrote terraform/backend.hcl (gitignored)." && \
		echo "Next: cd terraform && terraform init -backend-config=backend.hcl"

bootstrap-destroy:
	@echo ""
	@echo "WARNING: Destroy the app stack FIRST (make infra-destroy)."
	@echo "If the app stack still uses this bucket for remote state, you will lose"
	@echo "Terraform state and may leave orphaned AWS resources."
	@echo "This deletes the bootstrap state bucket and its contents."
	@echo ""
	@printf "Type 'destroy-bootstrap' to continue: " && read confirm && [ "$$confirm" = "destroy-bootstrap" ]
	cd $(ROOT)/terraform/bootstrap && terraform init
	cd $(ROOT)/terraform/bootstrap && terraform apply -var='force_destroy=true' -auto-approve -target=aws_s3_bucket.terraform_state
	cd $(ROOT)/terraform/bootstrap && terraform destroy -var='force_destroy=true'
	@rm -f $(ROOT)/terraform/backend.hcl
	@echo "Bootstrap destroyed. Removed terraform/backend.hcl if present."

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
	cd terraform && rm -rf .terraform && terraform init -backend=false && terraform validate

plan: build
	cd terraform && rm -rf .terraform && terraform init -backend=false && terraform plan

apply: build
	cd terraform && terraform apply

infra-destroy:
	@echo "This will destroy the app stack (CloudFront, Lambda, DynamoDB, etc)."
	@echo "Bootstrap state bucket is not included — use make bootstrap-destroy for that."
	cd terraform && terraform destroy

clean:
	rm -rf dist .pytest_cache
	find src -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
