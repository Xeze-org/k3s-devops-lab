# k3s DevOps Lab — task runner.
# On Windows without `make`, use the equivalent .\lab.ps1 <target> instead.
.DEFAULT_GOAL := help
SHELL := /bin/bash

ENV_FILE := .env

.PHONY: help preflight up apply sync status plan down clean-cf

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

preflight: ## Verify .env + required tools exist
	@test -f $(ENV_FILE) || { echo "ERROR: .env missing. Run: cp .env.example .env"; exit 1; }
	@. ./scripts/_lib.sh && require_env DOMAIN CF_API_TOKEN CF_ACCOUNT_ID GITHUB_TOKEN
	@command -v vagrant >/dev/null || { echo "ERROR: vagrant not on PATH"; exit 1; }
	@echo "preflight OK"

up: preflight ## Boot the VM and bootstrap everything
	bash scripts/render.sh
	@git add gitops/root/values.yaml && git commit -m "chore: render values from .env" --quiet || true
	@git push || echo "WARN: git push failed — ArgoCD reads from GitHub, push manually."
	vagrant up

apply: preflight ## Re-render flags, push, let ArgoCD reconcile
	bash scripts/render.sh
	git add gitops/root/values.yaml
	git commit -m "chore: toggle tools via .env" --quiet || echo "no changes to commit"
	git push
	@echo "Pushed. ArgoCD will reconcile within ~3 min (or run: make sync)."

sync: ## Force ArgoCD to reconcile now
	vagrant ssh -c "sudo kubectl -n argocd patch app root --type merge \
	  -p '{\"operation\":{\"sync\":{}}}' || true"

status: ## Show VM size, flags, ArgoCD apps, and tool URLs
	bash scripts/status.sh

plan: ## Ansible dry-run (re-provision in --check mode)
	vagrant provision --provision-with ansible_local 2>/dev/null || \
	  vagrant ssh -c "cd /vagrant && sudo ansible-playbook ansible/playbook.yml --check"

down: ## Destroy the VM
	vagrant destroy -f

clean-cf: ## Delete the Cloudflare tunnel + wildcard DNS (avoid orphans)
	bash scripts/clean-cf.sh
