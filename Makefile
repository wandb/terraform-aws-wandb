.DEFAULT_GOAL := help

.PHONY: format
format: ## Terraform Format
	terraform fmt --recursive

.PHONY: lint
lint: ## Terraform lint
	tflint --init --recursive --config .tflint.hcl 

.PHONY: docs
docs: ## Update terraform docs
	terraform-docs -c .terraform-docs.yml . --recursive

.PHONY: sast
sast: ## Run SAST scan on terraform
	docker run -t -v ${PWD}:/path checkmarx/kics:latest scan -p /path -o "/path/"

.PHONY: help
help: ## Shows all targets and help from the Makefile (this message).
	@grep --no-filename -E '^([a-z.A-Z_%-/]+:.*?)##' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?(## ?)"}; { \
			if (length($$1) > 0) { \
				printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2; \
			} else { \
				printf "%s\n", $$2; \
			} \
		}'
