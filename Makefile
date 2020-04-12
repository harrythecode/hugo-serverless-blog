.ONESHELL:
SHELL := /bin/bash
.PHONEY: help

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

validate-upload:
	@if [ -z $(S3_BUCKET) ]; then\
           echo "S3_BUCKET not set. Pass in S3_BUCKET=<s3 bucket name>"; exit 10;\
    fi

validate-create:
	@if [ -z `echo $(TITLE)|sed -E -e 's/[[:blank:]]+/-/g'` ]; then\
           echo "TITLE not set. Pass in TITLE=<title name>"; exit 10;\
    fi

create: validate-create ## Create a new post in posts folder
	@echo "== Creating new post"
	@hugo new posts/`date -u +'%Y/%m/%d/'``echo ${TITLE}|sed -E -e 's/[[:blank:]]+/-/g'`.md;

deploy: ## Deploy public folder
	@echo "== Deploying"
	@find ./public -type f -mtime +14 -exec rm -f {} \;
	@sh create_images.sh
	@hugo -t hugo-notepadium

server: ## Run a server locally
	@echo "== Run Hugo Server locally"
	@hugo server --bind=0.0.0.0 --baseURL=http://127.0.0.1:1313 -D -t hugo-notepadium

upload: validate-upload ## Upload Content to S3 bucket
	@echo "== Uploading"
	@AWS_PROFILE=terraform-init-user aws s3 sync --profile terraform-init-role --delete ./public/ s3://$(S3_BUCKET)/public/
